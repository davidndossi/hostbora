import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class EditUnitController extends BaseController {
  EditUnitController()
      : _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>();

  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _unitLocal;

  final formKey = GlobalKey<FormState>();
  final unitNameController = TextEditingController();
  final unitRentController = TextEditingController();
  final unitDescriptionController = TextEditingController();
  final unitRentFrequency = 'Per Month'.obs;
  final unitFloor = PropertyUnitFloor.defaultIndex.obs;

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
  int _targetIndex = -1;
  List<ApartmentUnitDraft> _units = const [];

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    loadError.value = '';
    try {
      final args = Get.arguments;
      final map = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
      final propertyRef = (map['property_ref'] ?? map['propertyRef'] ?? '').toString().trim();
      final targetUnitId = (map['unit_id'] ?? '').toString().trim();
      final targetUnitName = (map['unit_name'] ?? map['unitName'] ?? '').toString().trim();

      if (propertyRef.isEmpty) {
        loadError.value = _isSw ? 'Kitambulisho cha mali hakipo.' : 'Missing property reference.';
        return;
      }

      PropertyRecord? row = await _propertyLocal.getByPropertyRef(propertyRef);
      if (row == null) {
        loadError.value = _isSw ? 'Mali haijapatikana.' : 'Property was not found on this device.';
        return;
      }
      _property = row;

      final raw = row.unitsJson.trim();
      if (raw.isEmpty) {
        loadError.value = _isSw ? 'Hakuna unit za kuhariri.' : 'This property has no units to edit.';
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        loadError.value = _isSw ? 'Data ya unit si sahihi.' : 'Invalid unit data format.';
        return;
      }

      _units = decoded
          .whereType<Map>()
          .map((e) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (_units.isEmpty) {
        loadError.value = _isSw ? 'Hakuna unit za kuhariri.' : 'This property has no units to edit.';
        return;
      }

      _targetIndex = _units.indexWhere((u) {
        if (targetUnitId.isNotEmpty && u.unitId.trim().isNotEmpty) {
          return u.unitId.trim() == targetUnitId;
        }
        return false;
      });
      if (_targetIndex < 0 && targetUnitName.isNotEmpty) {
        _targetIndex = _units.indexWhere(
          (u) => u.unitName.trim().toLowerCase() == targetUnitName.toLowerCase(),
        );
      }
      if (_targetIndex < 0) _targetIndex = 0;

      final unit = _units[_targetIndex];
      unitNameController.text = unit.unitName;
      unitRentController.text = unit.unitRent;
      unitDescriptionController.text = unit.unitDescription;
      unitRentFrequency.value = _coerceFrequency(unit.unitRentFrequency, row.rentFrequency);
      unitFloor.value = unit.unitFloor;
    } catch (e, st) {
      logger.e('EditUnit load $e $st');
      loadError.value = _isSw ? 'Imeshindwa kupakia unit.' : 'Could not load unit details.';
    } finally {
      loading.value = false;
    }
  }

  String _coerceFrequency(String value, String fallback) {
    final v = value.trim();
    if (rentFrequencyOptions.contains(v)) return v;
    final fb = fallback.trim();
    if (rentFrequencyOptions.contains(fb)) return fb;
    return rentFrequencyOptions.first;
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

  Future<void> save() async {
    if (saving.value) return;
    final property = _property;
    if (property == null || _targetIndex < 0 || _targetIndex >= _units.length) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final updatedName = unitNameController.text.trim();
    final updatedRent = unitRentController.text.trim();
    final updatedDesc = unitDescriptionController.text.trim();

    final current = _units[_targetIndex];
    final updated = ApartmentUnitDraft(
      unitId: current.unitId,
      unitName: updatedName,
      unitRent: updatedRent,
      unitRentFrequency: unitRentFrequency.value,
      unitFloor: unitFloor.value,
      unitDescription: updatedDesc,
    );

    _units = List<ApartmentUnitDraft>.from(_units)..[_targetIndex] = updated;
    final unitsJson = jsonEncode(_units.map((u) => u.toJson()).toList());

    saving.value = true;
    await runBusy(() async {
      try {
      await _propertyLocal.update(
        PropertyRecord(
          id: property.id,
          propertyName: property.propertyName,
          propertyType: property.propertyType,
          propertyLocation: property.propertyLocation,
          propertyRef: property.propertyRef,
          tenants: property.tenants,
          units: _units.length,
          ownerUserId: property.ownerUserId,
          workspaceType: property.workspaceType,
          createdAtMs: property.createdAtMs,
          rentAmount: property.rentAmount,
          rentFrequency: property.rentFrequency,
          minRentalDuration: property.minRentalDuration,
          unitsJson: unitsJson,
          floorCount: property.floorCount,
        ),
      );

      final refs = <String>{
        if (property.propertyRef.trim().isNotEmpty) property.propertyRef.trim(),
        'local_${property.id}',
        'legacy_${property.id}',
      };
      for (final r in refs) {
        await syncPropertyUnitsForListingSave(
          unitLocal: _unitLocal,
          propertyRef: r,
          isApartment: true,
          apartmentUnitMaps: _units.map((u) => u.toJson()).toList(),
          minRentalDuration: property.minRentalDuration,
          listingRentFrequency: property.rentFrequency,
          listingRentRaw: property.rentAmount,
          singleUnitName: property.propertyName,
          rooms: 0,
          maxGuests: 0,
        );
      }

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

  @override
  void onClose() {
    unitNameController.dispose();
    unitRentController.dispose();
    unitDescriptionController.dispose();
    super.onClose();
  }
}
