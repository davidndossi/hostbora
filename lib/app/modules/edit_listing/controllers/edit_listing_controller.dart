import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/utils/property_name_rules.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class EditListingController extends BaseController {
  EditListingController()
      : _local = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>();

  final PropertyLocalDataSource _local;
  final PropertyUnitLocalDataSource _unitLocal;

  final formKey = GlobalKey<FormState>();
  final propertyLocationController = TextEditingController();
  final propertyNameController = TextEditingController();

  final loading = true.obs;
  final loadError = ''.obs;

  PropertyRecord? _original;
  String _snapLocation = '';
  String _snapName = '';
  String _snapUnitsCanon = '';

  final apartmentUnits = <ApartmentUnitDraft>[].obs;
  final draftUnitNameController = TextEditingController();
  final draftUnitRentController = TextEditingController();
  final draftUnitDescriptionController = TextEditingController();
  final draftUnitFloor = PropertyUnitFloor.defaultIndex.obs;
  final draftUnitMode = 'bnb'.obs;

  static const _rentFrequencyOptions = ['Per Day', 'Per Week', 'Per Month', 'Per Year'];

  bool get showUnitsEditor => isApartmentProperty;

  bool get isApartmentProperty => _original?.propertyType.trim() == 'Apartment';

  @override
  void onInit() {
    super.onInit();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    loading.value = true;
    loadError.value = '';
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      final propertyRef = (args?['property_ref'] ??
              args?['property_id'] ??
              args?['listing_id'] ??
              '')
          .toString()
          .trim();
      if (propertyRef.isEmpty) {
        loadError.value = 'Missing property reference.';
        return;
      }
      PropertyRecord? row = await _local.getByPropertyRef(propertyRef);
      if (row == null) {
        const lp = 'local_';
        if (propertyRef.startsWith(lp)) {
          final n = int.tryParse(propertyRef.substring(lp.length));
          if (n != null) row = await _local.getById(n);
        }
      }
      if (row == null) {
        const lg = 'legacy_';
        if (propertyRef.startsWith(lg)) {
          final n = int.tryParse(propertyRef.substring(lg.length));
          if (n != null) row = await _local.getById(n);
        }
      }
      if (row == null) {
        loadError.value = 'Property not found on this device.';
        return;
      }
      _original = row;
      _snapLocation = row.propertyLocation;
      _snapName = row.propertyName;
      propertyLocationController.text = row.propertyLocation;
      propertyNameController.text = row.propertyName;
      _loadUnitsFromRow(row);
      _snapUnitsCanon = isApartmentProperty && apartmentUnits.isNotEmpty
          ? _canonicalUnitsJsonFromDrafts(apartmentUnits)
          : '';

      // Pre-set unit draft mode + frequency from caller context.
      final rawMode = (args?['default_unit_mode'] ?? '').toString().trim().toLowerCase();
      if (rawMode == 'rent' || rawMode == 'bnb') {
        draftUnitMode.value = rawMode;
      }
    } catch (e, st) {
      logger.e('EditListing load $e $st');
      loadError.value = 'Could not load property.';
    } finally {
      loading.value = false;
    }
  }

  void _loadUnitsFromRow(PropertyRecord row) {
    apartmentUnits.clear();
    if (row.propertyType.trim() != 'Apartment') return;
    final raw = row.unitsJson.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          apartmentUnits.add(ApartmentUnitDraft.fromJson(e));
        } else if (e is Map) {
          apartmentUnits.add(ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } catch (_) {}
  }

  static String _canonicalUnitsJsonFromDrafts(List<ApartmentUnitDraft> drafts) {
    if (drafts.isEmpty) return '';
    final copies = drafts
        .map(
          (u) => ApartmentUnitDraft(
            unitId: u.unitId.trim(),
            unitName: u.unitName.trim(),
            unitRent: u.unitRent.trim(),
            unitRentFrequency: u.unitRentFrequency.trim(),
            unitFloor: u.unitFloor,
            unitDescription: u.unitDescription.trim(),
          ),
        )
        .toList()
      ..sort((a, b) {
        final c = a.unitName.toLowerCase().compareTo(b.unitName.toLowerCase());
        if (c != 0) return c;
        return a.unitId.toLowerCase().compareTo(b.unitId.toLowerCase());
      });
    return jsonEncode(copies.map((u) => u.toJson()).toList());
  }

  String _newApartmentUnitId() =>
      'u_${DateTime.now().microsecondsSinceEpoch}_${apartmentUnits.length}';

  void _ensureApartmentUnitIds() {
    if (!isApartmentProperty || apartmentUnits.isEmpty) return;
    final next = <ApartmentUnitDraft>[];
    var changed = false;
    for (final u in apartmentUnits) {
      if (u.unitId.trim().isEmpty) {
        next.add(
          ApartmentUnitDraft(
            unitId: _newApartmentUnitId(),
            unitName: u.unitName,
            unitRent: u.unitRent,
            unitRentFrequency: u.unitRentFrequency,
            unitFloor: u.unitFloor,
            unitDescription: u.unitDescription,
          ),
        );
        changed = true;
      } else {
        next.add(u);
      }
    }
    if (changed) apartmentUnits.assignAll(next);
  }

  void updateDraftUnitFloor(int? value) {
    if (value != null && PropertyUnitFloor.indices.contains(value)) {
      draftUnitFloor.value = value;
    }
  }

  void updateDraftUnitMode(String mode) {
    if (mode == draftUnitMode.value) return;
    draftUnitMode.value = mode;
  }

  String? validateDraftUnitRent(String? value) {
    if (apartmentUnits.isNotEmpty) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Unit rent is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validatePropertyName(String? value) => PropertyNameRules.validate(
        value,
        isSw: Get.locale?.languageCode == 'sw',
      );

  void addApartmentUnit() {
    final name = draftUnitNameController.text.trim();
    final rent = draftUnitRentController.text.trim();
    if (name.isEmpty || rent.isEmpty) {
      Get.snackbar('Error', 'Unit name and rent are required');
      return;
    }
    final mode = draftUnitMode.value;
    final defaultFreq = mode == 'rent' ? 'Per Month' : 'Per Day';
    final listingFreq = _original?.rentFrequency.trim() ?? '';
    final frequency = _rentFrequencyOptions.contains(listingFreq) ? listingFreq : defaultFreq;
    apartmentUnits.add(
      ApartmentUnitDraft(
        unitId: _newApartmentUnitId(),
        unitName: name,
        unitRent: rent,
        unitRentFrequency: frequency,
        unitFloor: draftUnitFloor.value,
        operationMode: mode,
        unitDescription: draftUnitDescriptionController.text.trim(),
      ),
    );
    draftUnitNameController.clear();
    draftUnitRentController.clear();
    draftUnitDescriptionController.clear();
    draftUnitFloor.value = PropertyUnitFloor.defaultIndex;
  }

  void removeApartmentUnit(int index) {
    if (index >= 0 && index < apartmentUnits.length) {
      apartmentUnits.removeAt(index);
    }
  }

  String _unitsJsonForSave() {
    if (!isApartmentProperty || apartmentUnits.isEmpty) {
      return '';
    }
    _ensureApartmentUnitIds();
    return jsonEncode(apartmentUnits.map((u) => u.toJson()).toList());
  }

  int _listedUnitCount() {
    if (isApartmentProperty && apartmentUnits.isNotEmpty) {
      return apartmentUnits.length;
    }
    final u = _original?.units ?? 0;
    return u > 0 ? u : 1;
  }

  Future<void> save() async {
    final orig = _original;
    if (orig == null) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final newLoc = propertyLocationController.text.trim();
    final newName = propertyNameController.text.trim();
    if (isApartmentProperty && apartmentUnits.isEmpty) {
      Get.snackbar('Error', 'Add at least one apartment unit');
      return;
    }

    final locChanged = newLoc != _snapLocation;
    final nameChanged = newName != _snapName;
    final unitsJsonOut = _unitsJsonForSave();
    final unitsCanonNow = isApartmentProperty && apartmentUnits.isNotEmpty
        ? _canonicalUnitsJsonFromDrafts(apartmentUnits)
        : '';
    final unitsChanged = unitsCanonNow != _snapUnitsCanon;

    if (!locChanged && !nameChanged && !unitsChanged) {
      Get.back(result: false);
      return;
    }

    await runBusy(() async {
      try {
      final merged = PropertyRecord(
        id: orig.id,
        propertyLocation: locChanged ? newLoc : orig.propertyLocation,
        propertyName: nameChanged ? newName : orig.propertyName,
        propertyType: orig.propertyType,
        propertyRef: orig.propertyRef,
        tenants: orig.tenants,
        units: unitsChanged ? _listedUnitCount() : orig.units,
        ownerUserId: orig.ownerUserId,
        workspaceType: orig.workspaceType,
        createdAtMs: orig.createdAtMs,
        rentAmount: orig.rentAmount,
        rentFrequency: orig.rentFrequency,
        minRentalDuration: orig.minRentalDuration,
        unitsJson: unitsChanged ? unitsJsonOut : orig.unitsJson,
        floorCount: orig.floorCount,
        coverPhotoPath: orig.coverPhotoPath,
      );

      await _local.update(merged);

      final ref = orig.propertyRef.trim();
      if (ref.isNotEmpty) {
        if (isApartmentProperty && apartmentUnits.isNotEmpty) {
          if (unitsChanged) {
            await syncPropertyUnitsForListingSave(
              unitLocal: _unitLocal,
              propertyRef: ref,
              isApartment: true,
              apartmentUnitMaps: apartmentUnits.map((u) => u.toJson()).toList(),
              minRentalDuration: orig.minRentalDuration,
              listingRentFrequency: orig.rentFrequency,
              listingRentRaw: orig.rentAmount,
              singleUnitName: merged.propertyName,
              rooms: 0,
              maxGuests: 0,
            );
          }
        } else if (nameChanged) {
          await syncPropertyUnitsForListingSave(
            unitLocal: _unitLocal,
            propertyRef: ref,
            isApartment: false,
            apartmentUnitMaps: const [],
            minRentalDuration: orig.minRentalDuration,
            listingRentFrequency: orig.rentFrequency,
            listingRentRaw: orig.rentAmount,
            singleUnitName: merged.propertyName,
            rooms: 0,
            maxGuests: 0,
          );
        }
      }

      Get.back(result: true);
      showSuccessWithHaptic('Property updated on this device');
    } catch (e, st) {
      logger.e('EditListing save $e $st');
      Get.snackbar('Error', 'Could not save changes');
    }
    });
  }

  @override
  void onClose() {
    propertyLocationController.dispose();
    propertyNameController.dispose();
    draftUnitNameController.dispose();
    draftUnitRentController.dispose();
    draftUnitDescriptionController.dispose();
    super.onClose();
  }
}
