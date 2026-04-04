import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../models/apartment_unit_draft.dart';

class RentAddNewListingController extends BaseController {
  RentAddNewListingController() : _local = Get.find<RentPropertyLocalDataSource>();

  final RentPropertyLocalDataSource _local;
  final propertyType = 'Apartment'.obs;
  final rentFrequency = 'Per Month'.obs;
  final minRentalDuration = '6 Months'.obs;
  final propertyTypeOptions = const ['Apartment', 'House', 'Studio', 'Villa'];
  final rentFrequencyOptions = const ['Per Day', 'Per Week', 'Per Month', 'Per Year'];
  final minRentalDurationOptions = const ['1 Month', '3 Months', '6 Months', '12 Months'];

  final propertyLocationController = TextEditingController();
  final apartmentSuiteController = TextEditingController();
  final rentAmountController = TextEditingController();

  final apartmentUnits = <ApartmentUnitDraft>[].obs;
  final draftUnitNameController = TextEditingController();
  final draftUnitRentController = TextEditingController();
  final draftUnitDescriptionController = TextEditingController();

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
      }
    }
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
        unitName: name,
        unitRent: rent,
        unitDescription: draftUnitDescriptionController.text.trim(),
      ),
    );
    draftUnitNameController.clear();
    draftUnitRentController.clear();
    draftUnitDescriptionController.clear();
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
    return jsonEncode(apartmentUnits.map((u) => u.toJson()).toList());
  }

  void updateRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      rentFrequency.value = value;
    }
  }

  void updateMinRentalDuration(String? value) {
    if (value != null && value.isNotEmpty) {
      minRentalDuration.value = value;
    }
  }

  Future<void> saveProperty() async {
    final location = propertyLocationController.text.trim();
    if (location.isEmpty) {
      Get.snackbar('Error', 'Please enter a property location');
      return;
    }
    showLoading();
    try {
      await _local.insert(
        RentPropertyRecord(
          id: 0,
          propertyLocation: location,
          apartmentSuite: apartmentSuiteController.text.trim(),
          propertyType: propertyType.value,
          rentAmount: rentAmountController.text.trim(),
          rentFrequency: rentFrequency.value,
          minRentalDuration: minRentalDuration.value,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          unitsJson: _unitsJsonForSave(),
        ),
      );
      Get.back(result: true);
      Get.snackbar('Saved', 'Property saved on this device');
    } catch (e, st) {
      logger.e('saveProperty $e $st');
      Get.snackbar('Error', 'Could not save property');
    } finally {
      hideLoading();
    }
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
