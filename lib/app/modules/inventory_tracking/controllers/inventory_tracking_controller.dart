import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '/app/core/base/base_controller.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/inventory_movement_local_data_source.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/model/inventory_item_request.dart';
import '/app/data/repository/app_repository.dart';
import '/app/routes/app_pages.dart';

class InventoryUnitOption {
  const InventoryUnitOption({
    required this.unitId,
    required this.unitName,
  });

  final String unitId;
  final String unitName;
}

class InventoryTrackingController extends BaseController {
  InventoryTrackingController()
      : _itemLocal = Get.find<InventoryItemLocalDataSource>(),
        _movementLocal = Get.find<InventoryMovementLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final InventoryItemLocalDataSource _itemLocal;
  final InventoryMovementLocalDataSource _movementLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final loading = true.obs;
  final propertyRef = ''.obs;
  final propertyName = ''.obs;
  final selectedUnitId = ''.obs;
  final availableUnits = <InventoryUnitOption>[].obs;
  final items = <InventoryItemRecord>[].obs;
  final totalItems = 0.obs;
  final lowStockCount = 0.obs;
  final recentlyChangedCount = 0.obs;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  /// True when the screen was opened without a propertyRef (e.g. from the home
  /// screen low-stock banner).  In this mode all inventory across all properties
  /// is shown read-only; the Add-Item FAB is hidden.
  bool get isGlobalMode => propertyRef.value.trim().isEmpty;

  @override
  void onInit() {
    super.onInit();
    propertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    propertyName.value = (Get.parameters['propertyName'] ?? '').trim();
    _loadUnitsFromArgs();
    loadAll();
  }

  void _loadUnitsFromArgs() {
    final raw = Get.arguments;
    if (raw is Map && raw['units'] is List) {
      final out = <InventoryUnitOption>[];
      for (final entry in raw['units'] as List) {
        if (entry is! Map) continue;
        final id = (entry['unitId'] ?? entry['unit_id'] ?? '').toString().trim();
        final name =
            (entry['unitName'] ?? entry['name'] ?? entry['unit_name'] ?? '')
                .toString()
                .trim();
        if (name.isEmpty) continue;
        out.add(InventoryUnitOption(unitId: id, unitName: name));
      }
      availableUnits.assignAll(out);
    }
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      await _mergeRemoteItems();
      await _reloadLocal();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _mergeRemoteItems() async {
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return;
    try {
      final res = await _repository.getInventoryItems(
        propertyRef: ref,
        apartmentUnitId: selectedUnitId.value.trim().isEmpty
            ? null
            : selectedUnitId.value.trim(),
      );
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) return;
      final data = res.data;
      List<dynamic> remote = const [];
      if (data is Map && data['items'] is List) {
        remote = data['items'] as List;
      } else if (data is List) {
        remote = data;
      }
      for (final row in remote) {
        if (row is Map) {
          await _itemLocal.upsertFromRemote(Map<String, dynamic>.from(row));
        }
      }
    } catch (_) {}
  }

  Future<void> _reloadLocal() async {
    final ref    = propertyRef.value.trim();
    final unitId = selectedUnitId.value.trim();

    final List<InventoryItemRecord> rows;
    if (ref.isEmpty) {
      // Global mode — show every item across all properties
      rows = await _itemLocal.listAll();
    } else {
      rows = await _itemLocal.listForProperty(
        propertyRef: ref,
        apartmentUnitId: unitId,
      );
    }

    items.assignAll(rows);
    totalItems.value   = rows.length;
    lowStockCount.value = rows.where((r) => r.isLowStock).length;

    // Recently-changed count: use all rows already loaded
    final ids   = rows.map((e) => e.id).toList();
    final since = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    recentlyChangedCount.value = ids.isEmpty
        ? 0
        : await _movementLocal.countRecentForProperty(
            itemLocalIds: ids,
            sinceMs: since,
          );
  }

  Future<void> selectUnit(String unitId) async {
    selectedUnitId.value = unitId.trim();
    await loadAll();
  }

  Future<void> onAddItem() async {
    final changed = await Get.toNamed(
      Routes.INVENTORY_ITEM_FORM,
      parameters: {
        'propertyRef': propertyRef.value,
        'propertyName': propertyName.value,
        'apartmentUnitId': selectedUnitId.value,
        'apartmentUnitName': _selectedUnitName(),
      },
    );
    if (changed == true) await loadAll();
  }

  Future<void> onEditItem(InventoryItemRecord item) async {
    final changed = await Get.toNamed(
      Routes.INVENTORY_ITEM_FORM,
      parameters: {
        'propertyRef': propertyRef.value,
        'propertyName': propertyName.value,
        'apartmentUnitId': item.apartmentUnitId,
        'apartmentUnitName': item.apartmentUnitName,
        'itemLocalId': '${item.id}',
      },
    );
    if (changed == true) await loadAll();
  }

  String _selectedUnitName() {
    final id = selectedUnitId.value.trim();
    if (id.isEmpty) return '';
    for (final u in availableUnits) {
      if (u.unitId == id) return u.unitName;
    }
    return '';
  }

  // ── Export ───────────────────────────────────────────────────────────────

  final exporting = false.obs;

  Future<void> exportToCsv({BuildContext? shareContext}) async {
    if (exporting.value) return;
    // Capture popover anchor before awaits (iOS requires a non-zero origin).
    final shareOrigin =
        _shareOrigin(shareContext) ?? _shareOrigin(Get.context);
    exporting.value = true;
    try {
      final ref = propertyRef.value.trim();
      final allItems = ref.isEmpty
          ? items.toList()
          : await _itemLocal.listAllForProperty(ref);
      if (allItems.isEmpty) {
        showErrorMessage(_isSw
            ? 'Hakuna vifaa vya kuhamisha.'
            : 'No inventory items to export.');
        return;
      }

      final buf = StringBuffer();
      buf.writeln(
        'Name,Category,Quantity,ReorderLevel,Condition,Location,Currency,PurchaseValue,Unit,Property',
      );
      String quoteCsv(String s) => '"${s.replaceAll('"', '""')}"';
      for (final it in allItems) {
        buf.writeln([
          quoteCsv(it.name),
          quoteCsv(it.category),
          it.quantity,
          it.reorderLevel,
          quoteCsv(it.condition),
          quoteCsv(it.locationNote),
          quoteCsv(it.currency),
          it.purchaseValue,
          quoteCsv(it.apartmentUnitName),
          quoteCsv(it.propertyLabel),
        ].join(','));
      }

      final dir  = await getTemporaryDirectory();
      final date = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final name = ref.isNotEmpty
          ? 'inventory_${ref.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$date.csv'
          : 'inventory_$date.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsString(buf.toString(), flush: true);
      final subjectLabel = propertyName.value.trim().isNotEmpty
          ? propertyName.value.trim()
          : (_isSw ? 'Mali Zote' : 'All Properties');
      final subject = _isSw
          ? 'Orodha ya Vifaa · $subjectLabel'
          : 'Inventory List · $subjectLabel';
      final xFile = XFile(file.path, mimeType: 'text/csv', name: name);
      await _shareInventoryFile(
        xFile: xFile,
        subject: subject,
        shareOrigin: shareOrigin,
      );
      showSuccessMessage(
        _isSw ? 'Faili iko tayari kushirikiwa.' : 'File ready to share.',
      );
    } catch (e) {
      showErrorMessage(
        _isSw
            ? 'Imeshindikana kushiriki orodha. Jaribu tena.'
            : 'Could not share the inventory file. Please try again.',
      );
    } finally {
      exporting.value = false;
    }
  }

  Future<void> _shareInventoryFile({
    required XFile xFile,
    required String subject,
    Rect? shareOrigin,
  }) async {
    var origin = shareOrigin;
    try {
      await Share.shareXFiles(
        [xFile],
        subject: subject,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      // iOS/iPad require a non-zero origin inside the source view bounds.
      final size = Get.size;
      origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 2,
        height: 2,
      );
      await Share.shareXFiles(
        [xFile],
        subject: subject,
        sharePositionOrigin: origin,
      );
    }
  }

  Rect? _shareOrigin(BuildContext? context) {
    final ctx = context;
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width <= 0 || origin.height <= 0) return null;
    return origin;
  }

  // ── Bulk import (CSV) ─────────────────────────────────────────────────────

  final importing = false.obs;

  /// Parse a CSV exported by [exportToCsv] and insert rows that don't yet exist.
  /// Rows with the same name + unit are skipped (idempotent).
  Future<void> importFromCsv(String csvContent) async {
    if (importing.value) return;
    importing.value = true;
    try {
      final ref = propertyRef.value.trim();
      if (ref.isEmpty) {
        showErrorMessage(
            _isSw ? 'Hakuna mali iliyochaguliwa.' : 'No property selected.');
        return;
      }

      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        showErrorMessage(_isSw ? 'Faili tupu.' : 'Empty file.');
        return;
      }
      // Skip header
      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _parseCsvLine(line);
        if (parts.length < 4) continue;
        final name = parts[0].trim();
        if (name.isEmpty) continue;
        final category    = parts.length > 1 ? parts[1].trim() : 'Other';
        final qty         = int.tryParse(parts.length > 2 ? parts[2].trim() : '') ?? 0;
        final reorder     = int.tryParse(parts.length > 3 ? parts[3].trim() : '') ?? 0;
        final condition   = parts.length > 4 ? parts[4].trim() : 'Good';
        final location    = parts.length > 5 ? parts[5].trim() : '';
        final currency    = parts.length > 6 ? parts[6].trim() : 'TZS';
        final purchaseVal = double.tryParse(parts.length > 7 ? parts[7].trim() : '') ?? 0;
        final unitName    = parts.length > 8 ? parts[8].trim() : '';

        final clientId =
            'import_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
        await _itemLocal.insert(
          clientItemId: clientId,
          propertyRef: ref,
          propertyLabel: propertyName.value,
          apartmentUnitId: '',
          apartmentUnitName: unitName,
          name: name,
          category: category.isEmpty ? 'Other' : category,
          quantity: qty,
          reorderLevel: reorder,
          condition: condition.isEmpty ? 'Good' : condition,
          locationNote: location,
          purchaseValue: purchaseVal,
          currency: currency.isEmpty ? 'TZS' : currency,
        );
        imported++;
      }

      await _reloadLocal();
      showSuccessMessage(
        _isSw
            ? '$imported ${imported == 1 ? 'kifaa kimerekodiwa' : 'vifaa vimerekodiwa'}.'
            : '$imported item${imported == 1 ? '' : 's'} imported.',
      );
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      importing.value = false;
    }
  }

  /// Minimal CSV line parser that handles quoted fields.
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf    = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  // ── Movement history ──────────────────────────────────────────────────────

  /// Loads the full movement history for [item].  Returned list is newest-first.
  Future<List<InventoryMovementRecord>> loadMovements(
      InventoryItemRecord item) async {
    return _movementLocal.listForItem(item.id);
  }

  // ── Stock adjustment ──────────────────────────────────────────────────────

  final adjusting = false.obs;

  Future<bool> adjustStock({
    required InventoryItemRecord item,
    required String movementType,
    required int quantityDelta,
    String notes = '',
  }) async {
    if (adjusting.value) {
      showErrorMessage(
        _isSw
            ? 'Subiri, bidhaa inasasishwa...'
            : 'Please wait — stock is still updating.',
      );
      return false;
    }
    if (quantityDelta == 0) {
      showErrorMessage(
        _isSw ? 'Weka idadi halali.' : 'Enter a valid quantity.',
      );
      return false;
    }
    final newQty = item.quantity + quantityDelta;
    if (newQty < 0) {
      showErrorMessage(
        _isSw
            ? 'Idadi haiwezi kuwa chini ya sifuri.'
            : 'Quantity cannot go below zero.',
      );
      return false;
    }

    adjusting.value = true;
    try {
      final clientMovementId =
          'mov_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
      final movementLocalId = await _movementLocal.insert(
        itemLocalId: item.id,
        clientMovementId: clientMovementId,
        movementType: movementType,
        quantityDelta: quantityDelta,
        notes: notes,
      );
      await _itemLocal.updateQuantity(item.id, newQty);

      // Refresh UI and confirm immediately — don't wait on the network.
      await _reloadLocal();
      showSuccessMessage(
        _isSw ? 'Bidhaa imesasishwa.' : 'Stock updated.',
      );

      // Sync to server in the background (or queue offline).
      unawaited(
        _syncMovementInBackground(
          item: item,
          movementLocalId: movementLocalId,
          clientMovementId: clientMovementId,
          movementType: movementType,
          quantityDelta: quantityDelta,
          notes: notes,
        ),
      );
      return true;
    } catch (_) {
      showErrorMessage(
        _isSw
            ? 'Imeshindikana kuhifadhi. Jaribu tena.'
            : 'Could not save the adjustment. Please try again.',
      );
      return false;
    } finally {
      adjusting.value = false;
    }
  }

  Future<void> _syncMovementInBackground({
    required InventoryItemRecord item,
    required int movementLocalId,
    required String clientMovementId,
    required String movementType,
    required int quantityDelta,
    required String notes,
  }) async {
    final backendId = item.backendItemId.trim();
    final movementRequest = InventoryMovementRequest(
      clientMovementId: clientMovementId,
      movementType: movementType,
      quantityDelta: quantityDelta,
      notes: notes,
    );

    if (backendId.isNotEmpty) {
      try {
        final res = await _repository.createInventoryMovement(
          backendId,
          movementRequest,
        );
        final saved = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!saved) throw Exception(res.message ?? 'movement failed');
        await _movementLocal.updateSyncStatus(movementLocalId, 'synced');
        await _itemLocal.updateSyncStatus(item.id, 'synced');
        final remoteId = (res.data is Map)
            ? ((res.data as Map)['movementId'] ?? (res.data as Map)['id'])
                ?.toString() ??
                ''
            : '';
        if (remoteId.isNotEmpty) {
          await _movementLocal.saveBackendMovementId(
            localId: movementLocalId,
            backendId: remoteId,
          );
        }
        return;
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'inventory_movement',
          operation: 'create',
          payloadJson: jsonEncode({
            'localMovementId': movementLocalId,
            'itemLocalId': item.id,
            'backendItemId': backendId,
            'clientMovementId': clientMovementId,
            'movementType': movementType,
            'quantityDelta': quantityDelta,
            'notes': notes,
          }),
        );
        _syncWorker.runNow();
        return;
      }
    }

    await _syncQueue.enqueue(
      entityType: 'inventory_movement',
      operation: 'create',
      payloadJson: jsonEncode({
        'localMovementId': movementLocalId,
        'itemLocalId': item.id,
        'clientMovementId': clientMovementId,
        'movementType': movementType,
        'quantityDelta': quantityDelta,
        'notes': notes,
      }),
    );
    _syncWorker.runNow();
  }
}
