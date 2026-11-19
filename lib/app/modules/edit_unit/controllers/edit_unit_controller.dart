import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/utils/property_remote_rent.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class EditUnitController extends BaseController {
  EditUnitController()
      : _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final AppRepository _repository;

  final formKey = GlobalKey<FormState>();
  final unitNameController = TextEditingController();
  final unitRentController = TextEditingController();
  final unitDescriptionController = TextEditingController();
  final unitRentFrequency = 'Per Month'.obs;
  final unitFloor = PropertyUnitFloor.defaultIndex.obs;
  final selectedCurrency = 'TZS'.obs;
  final operationMode = 'bnb'.obs;

  static const rentFrequencyOptions = [
    'Per Day',
    'Per Week',
    'Per Month',
    'Per Year',
  ];

  final loading = true.obs;
  final saving = false.obs;
  final loadError = ''.obs;

  PropertyRecord? _property;
  String _listingId = '';
  int _targetIndex = -1;
  List<ApartmentUnitDraft> _units = const [];

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onReady() {
    super.onReady();
    // Load after the route is ready so Get.arguments is populated.
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    loadError.value = '';
    try {
      final args = Get.arguments;
      final map = <String, dynamic>{
        ...Get.parameters,
        if (args is Map) ...Map<String, dynamic>.from(args),
      };
      final propertyRef =
          (map['property_ref'] ?? map['propertyRef'] ?? map['property_id'] ?? '')
              .toString()
              .trim();
      final propertyLocalIdRaw =
          map['property_local_id'] ?? map['propertyLocalId'];
      final propertyLocalId = propertyLocalIdRaw is int
          ? propertyLocalIdRaw
          : int.tryParse(propertyLocalIdRaw?.toString() ?? '');
      final targetUnitId = (map['unit_id'] ?? '').toString().trim();
      final targetUnitName =
          (map['unit_name'] ?? map['unitName'] ?? '').toString().trim();
      _listingId =
          (map['listing_id'] ?? map['listingId'] ?? '').toString().trim();
      final unitLocalIdRaw = map['unit_local_id'] ?? map['unitLocalId'];
      final unitLocalId = unitLocalIdRaw is int
          ? unitLocalIdRaw
          : int.tryParse(unitLocalIdRaw?.toString() ?? '');

      PropertyUnitRecord? localUnitRow;
      if (unitLocalId != null && unitLocalId > 0) {
        localUnitRow = await _unitLocal.getById(unitLocalId);
      }
      if (localUnitRow == null && targetUnitId.isNotEmpty) {
        localUnitRow = await _unitLocal.getByApartmentUnitId(targetUnitId);
      }

      PropertyRecord? row;
      if (propertyLocalId != null && propertyLocalId > 0) {
        row = await _propertyLocal.getById(propertyLocalId);
      }
      if (row == null && propertyRef.isNotEmpty) {
        row = await _propertyLocal.findByHubId(propertyRef);
      }
      if (row == null && localUnitRow != null) {
        final unitRef = localUnitRow.propertyRef.trim();
        if (unitRef.isNotEmpty) {
          row = await _propertyLocal.findByHubId(unitRef);
        }
      }
      // Last resort: find a local property that already contains this unit.
      if (row == null &&
          (targetUnitId.isNotEmpty || targetUnitName.isNotEmpty)) {
        row = await _findPropertyContainingUnit(
          unitId: targetUnitId,
          unitName: targetUnitName,
        );
      }

      if (row == null) {
        loadError.value = propertyRef.isEmpty &&
                unitLocalId == null &&
                propertyLocalId == null
            ? (_isSw
                ? 'Kitambulisho cha mali hakipo.'
                : 'Missing property reference.')
            : (_isSw
                ? 'Mali haijapatikana.'
                : 'Property was not found on this device.');
        return;
      }
      _property = row;

      _units = _parseUnitsFromJson(row.unitsJson);
      if (_units.isEmpty) {
        _units = await _unitsFromLocalTable(
          row,
          extraPropertyRefs: {
            if (propertyRef.isNotEmpty) propertyRef,
            if (localUnitRow != null && localUnitRow.propertyRef.trim().isNotEmpty)
              localUnitRow.propertyRef.trim(),
          },
        );
      }

      if (_units.isEmpty) {
        // Single-unit listings often store details only on the property row.
        final fallbackName = targetUnitName.isNotEmpty
            ? targetUnitName
            : (localUnitRow?.unitName.trim().isNotEmpty == true
                ? localUnitRow!.unitName.trim()
                : (row.propertyName.trim().isNotEmpty
                    ? row.propertyName.trim()
                    : row.propertyLocation.trim()));
        if (fallbackName.isEmpty && localUnitRow == null) {
          loadError.value = _isSw
              ? 'Hakuna unit za kuhariri kwenye kifaa hiki.'
              : 'No unit details are saved on this device to edit.';
          return;
        }
        _units = [
          ApartmentUnitDraft(
            unitId: (localUnitRow?.propertyUnitRef.trim().isNotEmpty == true)
                ? localUnitRow!.propertyUnitRef.trim()
                : (targetUnitId.isNotEmpty ? targetUnitId : 'main'),
            unitName: fallbackName.isNotEmpty ? fallbackName : 'Main unit',
            unitRent: localUnitRow != null && localUnitRow.rentAmount > 0
                ? _formatRentAmount(localUnitRow.rentAmount)
                : row.rentAmount,
            unitRentFrequency: (localUnitRow?.rentFrequency.trim().isNotEmpty == true)
                ? localUnitRow!.rentFrequency.trim()
                : row.rentFrequency,
            unitFloor: localUnitRow?.floor ?? PropertyUnitFloor.defaultIndex,
            operationMode: (localUnitRow?.operationMode.trim().isNotEmpty == true)
                ? localUnitRow!.operationMode
                : (row.workspaceType.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb'),
            unitDescription: localUnitRow?.notes ?? '',
            unitRentCurrency: (localUnitRow?.rentCurrency.trim().isNotEmpty == true)
                ? localUnitRow!.rentCurrency.trim().toUpperCase()
                : 'TZS',
          ),
        ];
      }

      final resolvedUnitId = targetUnitId.isNotEmpty
          ? targetUnitId
          : (localUnitRow?.propertyUnitRef.trim() ?? '');
      final resolvedUnitName = targetUnitName.isNotEmpty
          ? targetUnitName
          : (localUnitRow?.unitName.trim() ?? '');

      _targetIndex = _units.indexWhere((u) {
        if (resolvedUnitId.isNotEmpty && u.unitId.trim().isNotEmpty) {
          return u.unitId.trim() == resolvedUnitId;
        }
        return false;
      });
      if (_targetIndex < 0 && resolvedUnitName.isNotEmpty) {
        _targetIndex = _units.indexWhere(
          (u) => u.unitName.trim().toLowerCase() == resolvedUnitName.toLowerCase(),
        );
      }
      if (_targetIndex < 0) _targetIndex = 0;

      final unit = _units[_targetIndex];
      unitNameController.text = unit.unitName;
      unitRentController.text = unit.unitRent;
      unitDescriptionController.text = unit.unitDescription;
      // Resolve mode first so _coerceFrequency can use it as the tiebreaker.
      final resolvedMode =
          unit.operationMode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';
      operationMode.value = resolvedMode;
      unitRentFrequency.value =
          _coerceFrequency(unit.unitRentFrequency, row.rentFrequency, resolvedMode);
      unitFloor.value = unit.unitFloor;
      selectedCurrency.value = unit.unitRentCurrency.trim().isNotEmpty
          ? unit.unitRentCurrency.trim().toUpperCase()
          : 'TZS';
    } catch (e, st) {
      logger.e('EditUnit load $e $st');
      loadError.value = _isSw ? 'Imeshindwa kupakia unit.' : 'Could not load unit details.';
    } finally {
      loading.value = false;
    }
  }

  List<ApartmentUnitDraft> _parseUnitsFromJson(String unitsJson) {
    final raw = unitsJson.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Finds a local property that already stores [unitId] / [unitName].
  Future<PropertyRecord?> _findPropertyContainingUnit({
    required String unitId,
    required String unitName,
  }) async {
    final idKey = unitId.trim().toLowerCase();
    final nameKey = unitName.trim().toLowerCase();
    if (idKey.isEmpty && nameKey.isEmpty) return null;

    if (idKey.isNotEmpty) {
      final byUnit = await _unitLocal.getByApartmentUnitId(unitId.trim());
      if (byUnit != null) {
        final ref = byUnit.propertyRef.trim();
        if (ref.isNotEmpty) {
          final row = await _propertyLocal.findByHubId(ref);
          if (row != null) return row;
        }
      }
    }

    final rows = await _propertyLocal.getAllNewestFirst();
    for (final row in rows) {
      final units = _parseUnitsFromJson(row.unitsJson);
      for (final u in units) {
        if (idKey.isNotEmpty &&
            u.unitId.trim().toLowerCase() == idKey) {
          return row;
        }
        if (nameKey.isNotEmpty &&
            u.unitName.trim().toLowerCase() == nameKey) {
          return row;
        }
      }
      if (nameKey.isNotEmpty &&
          (row.propertyName.trim().toLowerCase() == nameKey ||
              row.apartmentSuite.trim().toLowerCase() == nameKey)) {
        return row;
      }
    }
    return null;
  }

  Future<List<ApartmentUnitDraft>> _unitsFromLocalTable(
    PropertyRecord row, {
    Set<String> extraPropertyRefs = const {},
  }) async {
    final refs = <String>{
      ...extraPropertyRefs.map((e) => e.trim()).where((e) => e.isNotEmpty),
      if (row.propertyRef.trim().isNotEmpty) row.propertyRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    };
    final byKey = <String, PropertyUnitRecord>{};
    for (final ref in refs) {
      final list = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final u in list) {
        final key = u.propertyUnitRef.trim().isNotEmpty
            ? u.propertyUnitRef.trim()
            : 'id_${u.id}';
        byKey.putIfAbsent(key, () => u);
      }
    }
    final drafts = byKey.values
        .map(_draftFromLocalUnit)
        .where((u) => u.unitName.trim().isNotEmpty)
        .toList();
    return drafts;
  }

  ApartmentUnitDraft _draftFromLocalUnit(PropertyUnitRecord u) {
    return ApartmentUnitDraft(
      unitId: u.propertyUnitRef.trim(),
      unitName: u.unitName.trim(),
      unitRent: u.rentAmount > 0 ? _formatRentAmount(u.rentAmount) : '',
      unitRentFrequency: u.rentFrequency.trim().isNotEmpty
          ? u.rentFrequency.trim()
          : 'Per Month',
      unitFloor: u.floor,
      operationMode: u.operationMode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb',
      unitDescription: u.notes,
      unitRentCurrency: u.rentCurrency.trim().isNotEmpty
          ? u.rentCurrency.trim().toUpperCase()
          : 'TZS',
    );
  }

  String _formatRentAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.round().toString();
    }
    return amount.toStringAsFixed(2);
  }

  String _coerceFrequency(String value, String fallback, String mode) {
    final v = value.trim();
    if (rentFrequencyOptions.contains(v)) return v;
    final fb = fallback.trim();
    if (rentFrequencyOptions.contains(fb)) return fb;
    // Fall back to mode-appropriate default: rent → Per Month, bnb → Per Day.
    return mode == 'rent' ? 'Per Month' : 'Per Day';
  }

  void updateRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      unitRentFrequency.value = value;
    }
  }

  void updateUnitFloor(int? value) {
    if (value != null && PropertyUnitFloor.indices.contains(value)) {
      unitFloor.value = value;
    }
  }

  void updateOperationMode(String mode) {
    if (mode == operationMode.value) return;
    operationMode.value = mode;
    if (mode == 'rent' && unitRentFrequency.value == 'Per Day') {
      unitRentFrequency.value = 'Per Month';
    } else if (mode == 'bnb' && unitRentFrequency.value == 'Per Month') {
      unitRentFrequency.value = 'Per Day';
    }
  }

  Future<void> save() async {
    if (saving.value) return;
    final property = _property;
    if (property == null || _targetIndex < 0 || _targetIndex >= _units.length) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final updatedName = unitNameController.text.trim();
    final updatedRent = unitRentController.text.trim().replaceAll(',', '');
    final updatedDesc = unitDescriptionController.text.trim();

    final current = _units[_targetIndex];
    final updated = ApartmentUnitDraft(
      unitId: current.unitId,
      unitName: updatedName,
      unitRent: updatedRent,
      unitRentFrequency: unitRentFrequency.value,
      unitFloor: unitFloor.value,
      unitDescription: updatedDesc,
      unitRentCurrency: selectedCurrency.value,
      operationMode: operationMode.value,
    );

    _units = List<ApartmentUnitDraft>.from(_units)..[_targetIndex] = updated;
    final unitsJson = jsonEncode(_units.map((u) => u.toJson()).toList());
    final canonicalRef = property.propertyRef.trim().isNotEmpty
        ? property.propertyRef.trim()
        : 'local_${property.id}';

    saving.value = true;
    await runBusy(() async {
      try {
      await _propertyLocal.update(
        property.copyWith(
          units: _units.length,
          unitsJson: unitsJson,
          rentAmount: _units.length == 1 ? updatedRent : property.rentAmount,
          rentFrequency: _units.length == 1
              ? unitRentFrequency.value
              : property.rentFrequency,
        ),
      );

      for (final alias in {
        canonicalRef,
        'local_${property.id}',
        'legacy_${property.id}',
        if (property.propertyRef.trim().isNotEmpty) property.propertyRef.trim(),
      }) {
        if (alias != canonicalRef) {
          await _unitLocal.deleteByPropertyRef(alias);
        }
      }
      await syncPropertyUnitsForListingSave(
        unitLocal: _unitLocal,
        propertyRef: canonicalRef,
        isApartment: true,
        apartmentUnitMaps: _units.map((u) => u.toJson()).toList(),
        minRentalDuration: property.minRentalDuration,
        listingRentFrequency: unitRentFrequency.value,
        listingRentRaw: updatedRent,
        singleUnitName: property.propertyName,
        rooms: 0,
        maxGuests: 0,
        listingMode: operationMode.value,
        listingRentCurrency: selectedCurrency.value,
      );

      final unitId = updated.unitId.trim().isNotEmpty
          ? updated.unitId.trim()
          : 'unit_index_$_targetIndex';
      await _pushUnitToRemote(
        property: property,
        unitsJson: unitsJson,
        rentAmount: _units.length == 1 ? updatedRent : property.rentAmount,
        rentFrequency: _units.length == 1
            ? unitRentFrequency.value
            : property.rentFrequency,
        unitId: unitId,
        unitBody: _remoteUnitBody(updated),
      );

      Get.back(result: true);
      showSuccessWithHaptic(_isSw ? 'Unit imehaririwa' : 'Unit updated');
    } catch (e, st) {
      logger.e('EditUnit save $e $st');
      showErrorMessage(_isSw ? 'Imeshindwa kuhifadhi unit.' : 'Could not save unit changes.');
    } finally {
      saving.value = false;
    }
    });
  }

  /// Remote properties keep unit details in `units_json`. The listing unit
  /// endpoint is updated as well when this screen was opened from a listing.
  Future<void> _pushUnitToRemote({
    required PropertyRecord property,
    required String unitsJson,
    required String rentAmount,
    required String rentFrequency,
    required String unitId,
    required Map<String, dynamic> unitBody,
  }) async {
    final ref = property.propertyRef.trim();
    final remoteRef = ref.isNotEmpty &&
            !ref.startsWith('local_') &&
            !ref.startsWith('legacy_')
        ? ref
        : '';
    if (remoteRef.isNotEmpty) {
      final rent = PropertyRemoteRent.amount(
        unitCount: _units.length,
        listingRentAmount: rentAmount,
        unitsJson: unitsJson,
      );
      final payload = <String, dynamic>{
        'property_ref': remoteRef,
        'location': property.propertyLocation,
        'name': property.propertyName,
        'type': property.propertyType,
        'units': _units.length,
        'workspace_type': property.workspaceType,
        'rent_amount': rent,
        'rent_frequency': PropertyRemoteRent.frequency(
          unitCount: _units.length,
          listingRentFrequency: rentFrequency,
          unitsJson: unitsJson,
          rentAmount: rent,
        ),
        'min_rental_duration': property.minRentalDuration,
        'units_json': unitsJson,
        'floor_count': property.floorCount,
        'cover_photo_path': property.coverPhotoPath,
      };
      try {
        if (Get.isRegistered<TenantLocalDataSource>()) {
          payload['tenants'] = await Get.find<TenantLocalDataSource>()
              .countByPropertyRef(remoteRef);
        }
        final res = await _repository.updatePropertyByRef(remoteRef, payload);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'updatePropertyByRef failed');
      } catch (_) {
        try {
          await _syncQueue.enqueue(
            entityType: 'property',
            operation: 'update',
            payloadJson: jsonEncode(payload),
            dedupeKey: 'property:update:$remoteRef',
          );
        } catch (_) {}
      }
    }

    final listingIds = <String>{
      if (remoteRef.isNotEmpty) remoteRef,
      if (_listingId.isNotEmpty &&
          !_listingId.startsWith('local_') &&
          !_listingId.startsWith('legacy_'))
        _listingId,
    };
    if (unitId.isNotEmpty && !unitId.startsWith('unit_index_')) {
      for (final listingId in listingIds) {
        try {
          await _syncQueue.enqueue(
            entityType: 'unit',
            operation: 'update',
            payloadJson: jsonEncode({
              'listingId': listingId,
              'unitId': unitId,
              'unit': unitBody,
            }),
            dedupeKey: 'unit:update:${listingId}_$unitId',
          );
        } catch (_) {}
      }
    }
    try {
      await _syncWorker.runNow();
    } catch (_) {}
  }

  Map<String, dynamic> _remoteUnitBody(ApartmentUnitDraft unit) {
    final rentNumber = double.tryParse(unit.unitRent.replaceAll(',', ''));
    return {
      ...unit.toJson(),
      'name': unit.unitName,
      'unit_name': unit.unitName,
      'description': unit.unitDescription,
      'unit_description': unit.unitDescription,
      'rent': unit.unitRent,
      'unit_rent': unit.unitRent,
      'price': rentNumber ?? unit.unitRent,
      'rentAmount': rentNumber ?? unit.unitRent,
      'rent_amount': rentNumber ?? unit.unitRent,
      'baseNightlyRate': rentNumber,
      'rentFrequency': unit.unitRentFrequency,
      'rent_frequency': unit.unitRentFrequency,
      'operation_mode': unit.operationMode,
      'floor': unit.unitFloor,
      'currency': unit.unitRentCurrency,
      'rentCurrency': unit.unitRentCurrency,
    };
  }

  @override
  void onClose() {
    unitNameController.dispose();
    unitRentController.dispose();
    unitDescriptionController.dispose();
    super.onClose();
  }
}
