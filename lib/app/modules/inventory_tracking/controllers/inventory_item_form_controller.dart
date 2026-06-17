import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/service/currency_service.dart';
import '/app/core/base/base_controller.dart';
import '/app/data/local/db/inventory_item_local_data_source.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/model/inventory_item_request.dart';
import '/app/data/repository/app_repository.dart';

class InventoryItemFormController extends BaseController {
  InventoryItemFormController()
      : _itemLocal = Get.find<InventoryItemLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final InventoryItemLocalDataSource _itemLocal;
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

  String propertyRef = '';
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
    propertyRef = (Get.parameters['propertyRef'] ?? '').trim();
    propertyName = (Get.parameters['propertyName'] ?? '').trim();
    apartmentUnitId = (Get.parameters['apartmentUnitId'] ?? '').trim();
    apartmentUnitName = (Get.parameters['apartmentUnitName'] ?? '').trim();
    final localIdRaw = (Get.parameters['itemLocalId'] ?? '').trim();
    if (localIdRaw.isNotEmpty) {
      editLocalId = int.tryParse(localIdRaw);
      _loadExisting();
    }
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
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
        _isSw ? 'Hakuna mali iliyochaguliwa.' : 'No property selected.',
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
