import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/property_listing_units_sync.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/property_unit_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/workspace_context_service.dart';
import '../../../../core/values/property_unit_floor.dart';
import '../models/apartment_unit_draft.dart';

class RentAddNewListingController extends BaseController {
  RentAddNewListingController()
      : _local = Get.find<PropertyLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _workspaceContext = Get.find<WorkspaceContextService>();

  final PropertyLocalDataSource _local;
  final PropertyUnitLocalDataSource _unitLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;
  final propertyType = 'Apartment'.obs;
  final rentFrequency = 'Per Month'.obs;
  final minRentalDuration = '6 Months'.obs;
  final propertyTypeOptions = const ['Apartment', 'House', 'Office space', 'Room', 'Storage', 'Other'];
  final rentFrequencyOptions = const ['Per Day', 'Per Week', 'Per Month', 'Per Year'];
  final minRentalDurationOptions = const ['1 Month', '3 Months', '6 Months', '12 Months'];

  static const int minFloorCount = 1;
  static const int maxFloorCount = 200;
  final floorCount = 1.obs;

  final propertyLocationController = TextEditingController();
  final apartmentSuiteController = TextEditingController();
  final rentAmountController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final apartmentUnits = <ApartmentUnitDraft>[].obs;
  final draftUnitNameController = TextEditingController();
  final draftUnitRentController = TextEditingController();
  final draftUnitDescriptionController = TextEditingController();
  final draftUnitRentFrequency = 'Per Month'.obs;
  final draftUnitFloor = PropertyUnitFloor.defaultIndex.obs;

  /// True after a local property is loaded for editing (route param `propertyRef`).
  final isEditing = false.obs;
  /// Full-screen load while resolving `propertyRef` (only when that param is present).
  final awaitingEditLoad = false.obs;

  PropertyRecord? _editingOriginal;

  bool get isApartmentProperty => propertyType.value == 'Apartment';

  /// Hide listing-level rent row when apartment has at least one unit (rent is per unit).
  bool get hideListingRentAmount => isApartmentProperty && apartmentUnits.isNotEmpty;

  void updatePropertyType(String? value) {
    if (value != null && value.isNotEmpty) {
      propertyType.value = value;
      if (value != 'Apartment') {
        apartmentUnits.clear();
        draftUnitNameController.clear();
        draftUnitRentController.clear();
        draftUnitDescriptionController.clear();
        draftUnitRentFrequency.value =
            _coerceOption(rentFrequency.value, rentFrequencyOptions);
        draftUnitFloor.value = PropertyUnitFloor.defaultIndex;
      }
    }
  }

  String _newApartmentUnitId() =>
      'u_${DateTime.now().microsecondsSinceEpoch}_${apartmentUnits.length}';

  /// Ensures every unit has a persistent [ApartmentUnitDraft.unitId] in JSON.
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
            unitRentFrequency:
                _coerceOption(u.unitRentFrequency, rentFrequencyOptions),
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

  void addApartmentUnit() {
    final name = draftUnitNameController.text.trim();
    final rent = draftUnitRentController.text.trim();
    if (name.isEmpty || rent.isEmpty) {
      Get.snackbar('Error', 'Unit name and rent are required');
      return;
    }
    apartmentUnits.add(
      ApartmentUnitDraft(
        unitId: _newApartmentUnitId(),
        unitName: name,
        unitRent: rent,
        unitRentFrequency:
            _coerceOption(draftUnitRentFrequency.value, rentFrequencyOptions),
        unitFloor: draftUnitFloor.value,
        unitDescription: draftUnitDescriptionController.text.trim(),
      ),
    );
    draftUnitNameController.clear();
    draftUnitRentController.clear();
    draftUnitDescriptionController.clear();
    draftUnitRentFrequency.value =
        _coerceOption(rentFrequency.value, rentFrequencyOptions);
    draftUnitFloor.value = PropertyUnitFloor.defaultIndex;
  }

  void updateDraftUnitFloor(int? value) {
    if (value != null && PropertyUnitFloor.indices.contains(value)) {
      draftUnitFloor.value = value;
    }
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
    return 1;
  }

  void updateRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      rentFrequency.value = value;
    }
  }

  void updateDraftUnitRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      draftUnitRentFrequency.value = value;
    }
  }

  void updateMinRentalDuration(String? value) {
    if (value != null && value.isNotEmpty) {
      minRentalDuration.value = value;
    }
  }

  void incrementFloorCount() {
    if (floorCount.value < maxFloorCount) floorCount.value++;
  }

  void decrementFloorCount() {
    if (floorCount.value > minFloorCount) floorCount.value--;
  }

  String _coerceOption(String raw, List<String> options) {
    final v = raw.trim();
    if (options.contains(v)) return v;
    return options.first;
  }

  Future<void> _loadPropertyForEdit(String hubId) async {
    try {
      final row = await _local.findByHubId(hubId);
      if (row == null) {
        Get.snackbar(
          'Error',
          'This property can only be edited if it was saved on this device.',
        );
        if (hubId.isNotEmpty) {
          Future.microtask(() => Get.back());
        }
        return;
      }
      _editingOriginal = row;
      isEditing.value = true;
      propertyLocationController.text = row.propertyLocation;
      apartmentSuiteController.text = row.apartmentSuite;
      propertyType.value = _coerceOption(row.propertyType, propertyTypeOptions);
      rentFrequency.value = _coerceOption(row.rentFrequency, rentFrequencyOptions);
      minRentalDuration.value = _coerceOption(row.minRentalDuration, minRentalDurationOptions);
      rentAmountController.text = row.rentAmount;
      floorCount.value = row.floorCount.clamp(minFloorCount, maxFloorCount);
      draftUnitRentFrequency.value =
          _coerceOption(rentFrequency.value, rentFrequencyOptions);
      apartmentUnits.clear();
      final unitsRaw = row.unitsJson.trim();
      if (unitsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(unitsRaw);
          if (decoded is List) {
            for (final e in decoded) {
              if (e is Map) {
                final draft =
                    ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(e));
                apartmentUnits.add(
                  ApartmentUnitDraft(
                    unitId: draft.unitId,
                    unitName: draft.unitName,
                    unitRent: draft.unitRent,
                    unitRentFrequency: _coerceOption(
                      draft.unitRentFrequency,
                      rentFrequencyOptions,
                    ),
                    unitFloor: draft.unitFloor,
                    unitDescription: draft.unitDescription,
                  ),
                );
              }
            }
          }
        } catch (e, st) {
          logger.e('parse unitsJson $e $st');
        }
      }
      _ensureApartmentUnitIds();
    } catch (e, st) {
      logger.e('_loadPropertyForEdit $e $st');
      Get.snackbar('Error', 'Could not load property');
    }
  }

  @override
  void onReady() {
    super.onReady();
    var hubId = Get.parameters['propertyRef']?.trim() ?? '';
    if (hubId.isEmpty) {
      final args = Get.arguments;
      if (args is Map) {
        hubId = (args['listing_id'] ??
                args['propertyRef'] ??
                args['property_id'] ??
                '')
            .toString()
            .trim();
      }
    }
    if (hubId.isEmpty) return;
    awaitingEditLoad.value = true;
    _loadPropertyForEdit(hubId).whenComplete(() {
      awaitingEditLoad.value = false;
    });
  }

  Future<void> saveProperty() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final location = propertyLocationController.text.trim();
    if (location.isEmpty) {
      Get.snackbar('Error', 'Please enter a property location');
      return;
    }
    if (isApartmentProperty && apartmentUnits.isEmpty) {
      Get.snackbar('Error', 'Add at least one apartment unit');
      return;
    }
    if (!hideListingRentAmount) {
      final rentRaw = rentAmountController.text.trim().replaceAll(',', '');
      final rentValue = double.tryParse(rentRaw);
      if (rentValue == null || rentValue <= 0) {
        Get.snackbar('Error', 'Please enter a valid rent amount');
        return;
      }
    }
    showLoading();
    try {
      final original = _editingOriginal;
      final unitsJson = _unitsJsonForSave();
      if (original != null) {
        final rentOut = hideListingRentAmount ? '' : rentAmountController.text.trim();
        await _local.update(
          PropertyRecord(
            id: original.id,
            propertyLocation: location,
            propertyName: apartmentSuiteController.text.trim(),
            propertyType: propertyType.value,
            propertyRef: original.propertyRef,
            tenants: original.tenants,
            units: _listedUnitCount(),
            ownerUserId: original.ownerUserId,
            workspaceType: original.workspaceType,
            createdAtMs: original.createdAtMs,
            rentAmount: rentOut,
            rentFrequency: rentFrequency.value,
            minRentalDuration: minRentalDuration.value,
            unitsJson: unitsJson,
            floorCount: floorCount.value,
          ),
        );
        await syncPropertyUnitsForListingSave(
          unitLocal: _unitLocal,
          propertyRef: original.propertyRef,
          isApartment: isApartmentProperty,
          apartmentUnitMaps: isApartmentProperty && apartmentUnits.isNotEmpty
              ? apartmentUnits.map((u) => u.toJson()).toList()
              : const [],
          minRentalDuration: minRentalDuration.value,
          listingRentFrequency: rentFrequency.value,
          listingRentRaw: rentAmountController.text.trim(),
          singleUnitName: apartmentSuiteController.text.trim(),
          rooms: 0,
          maxGuests: 0,
        );
        Get.back(result: true);
        Get.snackbar('Saved', 'Property updated on this device');
      } else {
        final workspaceType = await _workspaceContext.getWorkspaceType();
        final propertyRef = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await _local.insert(
          PropertyRecord(
            id: 0,
            propertyLocation: location,
            propertyName: apartmentSuiteController.text.trim(),
            propertyType: propertyType.value,
            propertyRef: propertyRef,
            tenants: 0,
            units: _listedUnitCount(),
            ownerUserId: (await _preferenceManager.getUser()).id ?? '',
            workspaceType: workspaceType,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
            rentAmount: rentAmountController.text.trim(),
            rentFrequency: rentFrequency.value,
            minRentalDuration: minRentalDuration.value,
            unitsJson: unitsJson,
            floorCount: floorCount.value,
          ),
        );
        await syncPropertyUnitsForListingSave(
          unitLocal: _unitLocal,
          propertyRef: propertyRef,
          isApartment: isApartmentProperty,
          apartmentUnitMaps: isApartmentProperty && apartmentUnits.isNotEmpty
              ? apartmentUnits.map((u) => u.toJson()).toList()
              : const [],
          minRentalDuration: minRentalDuration.value,
          listingRentFrequency: rentFrequency.value,
          listingRentRaw: rentAmountController.text.trim(),
          singleUnitName: apartmentSuiteController.text.trim(),
          rooms: 0,
          maxGuests: 0,
        );
        Get.back(result: true);
        Get.snackbar('Saved', 'Property saved on this device');
      }
    } catch (e, st) {
      logger.e('saveProperty $e $st');
      Get.snackbar('Error', 'Could not save property');
    } finally {
      hideLoading();
    }
  }

  String? validateLocation(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Property location is required';
    if (v.length < 3) return 'Enter a valid location';
    return null;
  }

  String? validateRentAmount(String? value) {
    if (hideListingRentAmount) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Rent amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validateDraftUnitRent(String? value) {
    if (apartmentUnits.isNotEmpty) return null;
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Unit rent is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  @override
  void onClose() {
    propertyLocationController.dispose();
    apartmentSuiteController.dispose();
    rentAmountController.dispose();
    draftUnitNameController.dispose();
    draftUnitRentController.dispose();
    draftUnitDescriptionController.dispose();
    super.onClose();
  }
}
