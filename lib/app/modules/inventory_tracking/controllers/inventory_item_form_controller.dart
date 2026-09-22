import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/service/currency_service.dart';
import '/app/core/base/base_controller.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/db/property_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/local/service/remote_account_sync_service.dart';
import '/app/data/model/inventory_item_request.dart';
import '/app/data/repository/app_repository.dart';
import '/l10n/app_localizations.dart';

class InventoryPropertyOption {
  const InventoryPropertyOption({
    required this.ref,
    required this.label,
  });

  final String ref;
  final String label;
}

class InventoryItemFormController extends BaseController {
  InventoryItemFormController()
      : _itemLocal = Get.find<InventoryItemLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final InventoryItemLocalDataSource _itemLocal;
  final PropertyLocalDataSource _propertyLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final reorderLevelController = TextEditingController(text: '0');
  final locationNoteController = TextEditingController();
  final purchaseValueController = TextEditingController();

  final saving = false.obs;
  final selectedCategory = 'Other'.obs;
  final selectedCondition = 'Good'.obs;

  final propertyOptions = <InventoryPropertyOption>[].obs;
  final selectedPropertyRef = ''.obs;
  final loadingProperties = false.obs;

  String get propertyRef => selectedPropertyRef.value.trim();
  String propertyName = '';
  String apartmentUnitId = '';
  String apartmentUnitName = '';
  int? editLocalId;

  static const categories = [
    'Furniture',
    'Appliances',
    'Linens',
    'Kitchen',
    'Bathroom',
    'Tools',
    'Other',
  ];

  static const conditions = ['Good', 'Fair', 'Poor', 'Damaged'];

  static const rooms = [
    'Living Room',
    'Bedroom 1',
    'Bedroom 2',
    'Bedroom 3',
    'Kitchen',
    'Bathroom',
    'Laundry',
    'Storage',
    'Balcony',
    'Reception',
    'Office',
    'Other',
  ];

  final selectedRoom = ''.obs;

  bool get isEditing => editLocalId != null;
  bool get _isSw => Get.locale?.languageCode == 'sw';

  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

  @override
  void onInit() {
    super.onInit();
    selectedPropertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    propertyName = (Get.parameters['propertyName'] ?? '').trim();
    apartmentUnitId = (Get.parameters['apartmentUnitId'] ?? '').trim();
    apartmentUnitName = (Get.parameters['apartmentUnitName'] ?? '').trim();
    final localIdRaw = (Get.parameters['itemLocalId'] ?? '').trim();
    if (localIdRaw.isNotEmpty) {
      editLocalId = int.tryParse(localIdRaw);
    }
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    _hydrateForm();
  }

  Future<void> _hydrateForm() async {
    if (editLocalId != null) {
      await _loadExisting();
    }
    await _loadProperties();
  }

  Future<void> _loadExisting() async {
    final id = editLocalId;
    if (id == null) return;
    final row = await _itemLocal.getById(id);
    if (row == null) return;
    nameController.text = row.name;
    quantityController.text = '${row.quantity}';
    reorderLevelController.text = '${row.reorderLevel}';
    locationNoteController.text = row.locationNote;
    purchaseValueController.text =
        row.purchaseValue > 0 ? '${row.purchaseValue}' : '';
    selectedCategory.value = row.category;
    selectedCondition.value = row.condition;
    // Restore room if location matches a preset
    final loc = row.locationNote.trim();
    if (rooms.contains(loc)) {
      selectedRoom.value = loc;
    } else {
      selectedRoom.value = '';
    }
    selectedCurrency.value = row.currency.trim().isNotEmpty
        ? row.currency.trim().toUpperCase()
        : CurrencyService.defaultBaseCurrency;
    apartmentUnitId = row.apartmentUnitId;
    apartmentUnitName = row.apartmentUnitName;
    final existingRef = row.propertyRef.trim();
    if (existingRef.isNotEmpty) {
      selectedPropertyRef.value = existingRef;
    }
    final existingLabel = row.propertyLabel.trim();
    if (existingLabel.isNotEmpty) {
      propertyName = existingLabel;
    }
  }

  Future<void> _loadProperties() async {
    loadingProperties.value = true;
    try {
      var userId = '';
      try {
        final prefs = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );
        userId = (await prefs.getUser()).id ?? '';
      } catch (_) {}

      var rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: 'all',
      );
      if (rows.isEmpty && userId.isNotEmpty) {
        rows = await _propertyLocal.getAllVisibleNewestFirst(
          userId: '',
          workspaceType: 'all',
        );
      }
      if (rows.isEmpty) {
        rows = await _propertyLocal.getAllNewestFirst();
      }
      if (rows.isEmpty) {
        try {
          if (Get.isRegistered<RemoteAccountSyncService>()) {
            await Get.find<RemoteAccountSyncService>()
                .syncPropertiesFromRemote();
          }
          rows = await _propertyLocal.getAllVisibleNewestFirst(
            userId: userId,
            workspaceType: 'all',
          );
          if (rows.isEmpty) {
            rows = await _propertyLocal.getAllNewestFirst();
          }
        } catch (_) {}
      }

      final options = <InventoryPropertyOption>[];
      final seen = <String>{};
      for (final p in rows) {
        final ref = p.propertyRef.trim().isNotEmpty
            ? p.propertyRef.trim()
            : 'local_${p.id}';
        if (seen.contains(ref)) continue;
        seen.add(ref);
        options.add(
          InventoryPropertyOption(ref: ref, label: _labelForProperty(p)),
        );
      }
      propertyOptions.assignAll(options);
      _ensureSelectedOptionPresent();

      if (!isEditing &&
          selectedPropertyRef.value.isEmpty &&
          options.length == 1) {
        updateSelectedProperty(options.first.ref);
      } else if (selectedPropertyRef.value.isNotEmpty) {
        propertyName = _labelForRef(selectedPropertyRef.value);
      }
    } finally {
      loadingProperties.value = false;
    }
  }

  String _labelForProperty(PropertyRecord p) {
    final name = p.propertyName.trim();
    if (name.isNotEmpty) return name;
    final loc = p.propertyLocation.trim();
    if (loc.isNotEmpty) return loc;
    final ref = p.propertyRef.trim();
    return ref.isNotEmpty ? ref : 'local_${p.id}';
  }

  String _labelForRef(String ref) {
    final key = ref.trim();
    for (final o in propertyOptions) {
      if (o.ref == key) return o.label;
    }
    if (propertyName.trim().isNotEmpty) return propertyName.trim();
    return key;
  }

  void _ensureSelectedOptionPresent() {
    final ref = selectedPropertyRef.value.trim();
    if (ref.isEmpty) return;
    if (propertyOptions.any((o) => o.ref == ref)) return;
    propertyOptions.add(
      InventoryPropertyOption(
        ref: ref,
        label: propertyName.trim().isNotEmpty ? propertyName.trim() : ref,
      ),
    );
  }

  void updateSelectedProperty(String? ref) {
    if (ref == null) return;
    selectedPropertyRef.value = ref.trim();
    propertyName = _labelForRef(ref);
  }

  String? validateSelectedProperty(String? value) {
    final v = (value ?? selectedPropertyRef.value).trim();
    if (v.isEmpty) {
      return _l10n?.inventoryPropertyRequired ??
          (_isSw ? 'Mali inahitajika' : 'Property is required');
    }
    return null;
  }

  AppLocalizations? get _l10n {
    final ctx = Get.context;
    if (ctx == null) return null;
    return AppLocalizations.of(ctx);
  }

  @override
  void onClose() {
    nameController.dispose();
    quantityController.dispose();
    reorderLevelController.dispose();
    locationNoteController.dispose();
    purchaseValueController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (propertyRef.isEmpty) {
      showErrorMessage(
        _l10n?.inventoryNoPropertySelected ??
            (_isSw ? 'Hakuna mali iliyochaguliwa.' : 'No property selected.'),
      );
      return;
    }

    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    final reorderLevel =
        int.tryParse(reorderLevelController.text.trim()) ?? 0;
    final purchaseValue =
        double.tryParse(purchaseValueController.text.trim()) ?? 0;

    saving.value = true;
    try {
      if (isEditing) {
        await _updateItem(
          name: name,
          quantity: quantity,
          reorderLevel: reorderLevel,
          purchaseValue: purchaseValue,
        );
      } else {
        await _createItem(
          name: name,
          quantity: quantity,
          reorderLevel: reorderLevel,
          purchaseValue: purchaseValue,
        );
      }
      Get.back(result: true);
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      saving.value = false;
    }
  }

  String get _currencyCode {
    final code = selectedCurrency.value.trim().toUpperCase();
    return code.isEmpty ? CurrencyService.defaultBaseCurrency : code;
  }

  Future<void> _createItem({
    required String name,
    required int quantity,
    required int reorderLevel,
    required double purchaseValue,
  }) async {
    final clientItemId =
        'item_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
    final localId = await _itemLocal.insert(
      clientItemId: clientItemId,
      propertyRef: propertyRef,
      propertyLabel: propertyName,
      apartmentUnitId: apartmentUnitId,
      apartmentUnitName: apartmentUnitName,
      name: name,
      category: selectedCategory.value,
      quantity: quantity,
      reorderLevel: reorderLevel,
      condition: selectedCondition.value,
      locationNote: locationNoteController.text.trim(),
      purchaseValue: purchaseValue,
      currency: _currencyCode,
    );

    final request = InventoryItemRequest(
      clientItemId: clientItemId,
      propertyRef: propertyRef,
      propertyLabel: propertyName,
      apartmentUnitId: apartmentUnitId,
      apartmentUnitName: apartmentUnitName,
      name: name,
      category: selectedCategory.value,
      quantity: quantity,
      reorderLevel: reorderLevel,
      condition: selectedCondition.value,
      locationNote: locationNoteController.text.trim(),
      purchaseValue: purchaseValue > 0 ? purchaseValue : null,
      currency: _currencyCode,
    );

    try {
      final res = await _repository.createInventoryItem(request);
      final saved = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!saved) throw Exception(res.message ?? 'create failed');
      await _itemLocal.updateSyncStatus(localId, 'synced');
      final backendId = (res.data is Map)
          ? ((res.data as Map)['itemId'] ?? (res.data as Map)['id'])
              ?.toString() ??
              ''
          : '';
      if (backendId.isNotEmpty) {
        await _itemLocal.saveBackendItemId(
          localId: localId,
          backendId: backendId,
        );
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'inventory_item',
        operation: 'create',
        payloadJson: jsonEncode({
          'localId': localId,
          ...request.toJson(),
        }),
      );
      _syncWorker.runNow();
    }
  }

  Future<void> _updateItem({
    required String name,
    required int quantity,
    required int reorderLevel,
    required double purchaseValue,
  }) async {
    final localId = editLocalId!;
    final existing = await _itemLocal.getById(localId);
    if (existing == null) throw Exception('Item not found');

    await _itemLocal.update(
      id: localId,
      name: name,
      category: selectedCategory.value,
      quantity: quantity,
      reorderLevel: reorderLevel,
      condition: selectedCondition.value,
      locationNote: locationNoteController.text.trim(),
      purchaseValue: purchaseValue,
      currency: _currencyCode,
      apartmentUnitId: apartmentUnitId,
      apartmentUnitName: apartmentUnitName,
      propertyRef: propertyRef,
      propertyLabel: propertyName,
    );

    final request = InventoryItemRequest(
      clientItemId: existing.clientItemId,
      propertyRef: propertyRef,
      propertyLabel: propertyName,
      apartmentUnitId: apartmentUnitId,
      apartmentUnitName: apartmentUnitName,
      name: name,
      category: selectedCategory.value,
      quantity: quantity,
      reorderLevel: reorderLevel,
      condition: selectedCondition.value,
      locationNote: locationNoteController.text.trim(),
      purchaseValue: purchaseValue > 0 ? purchaseValue : null,
      currency: _currencyCode,
    );

    final backendId = existing.backendItemId.trim();
    if (backendId.isEmpty) {
      await _syncQueue.enqueue(
        entityType: 'inventory_item',
        operation: 'update',
        payloadJson: jsonEncode({
          'localId': localId,
          ...request.toJson(),
        }),
      );
      _syncWorker.runNow();
      return;
    }

    try {
      final res = await _repository.updateInventoryItem(backendId, request);
      final saved = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!saved) throw Exception(res.message ?? 'update failed');
      await _itemLocal.updateSyncStatus(localId, 'synced');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'inventory_item',
        operation: 'update',
        payloadJson: jsonEncode({
          'localId': localId,
          'backendItemId': backendId,
          ...request.toJson(),
        }),
      );
      _syncWorker.runNow();
    }
  }

  String? validatePurchaseValue(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Purchase value is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid purchase value';
    return null;
  }
}
