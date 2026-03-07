import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class AddListingController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final propertyNameController = TextEditingController();
  final streetAddressController = TextEditingController();

  static const int totalSteps = 5;
  final currentStep = 1.obs;

  final selectedPropertyType = Rx<String?>(null);
  final propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'Cabin',
    'Studio',
    'Other',
  ];

  /// Step 2: photo slots (e.g. Living Room, Bedroom). Filled count for "X/4 slots filled".
  final photoSlotsFilled = 0.obs;
  static const int photoSlotsCount = 4;

  /// Step 3: Pricing & Rules
  final baseNightlyRateController = TextEditingController(text: '0.00');
  final cleaningFeeController = TextEditingController(text: '0.00');
  final instantBook = true.obs;
  final petsAllowed = false.obs;

  void goBack() {
    if (currentStep.value > 1) {
      currentStep.value--;
    } else {
      Get.back();
    }
  }

  void saveDraft() {
    // TODO: persist draft and optionally go back
    Get.back();
  }

  void nextStep() {
    if (currentStep.value == 1) {
      if (formKey.currentState?.validate() ?? false) {
        currentStep.value = 2;
      }
    } else if (currentStep.value == 2) {
      currentStep.value = 3;
    } else if (currentStep.value == 3) {
      currentStep.value = 4;
    } else {
      Get.back();
    }
  }

  void publishListing() {
    // TODO: persist listing to backend, then navigate to success screen
    Get.offNamed(Routes.LISTING_PUBLISHED);
  }

  void editListingDetails() {
    currentStep.value = 1;
  }

  void openHelp() {
    Get.snackbar('Help', 'Add listing help can be shown here.');
  }

  void selectPropertyType(String? value) {
    selectedPropertyType.value = value;
  }

  String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  void onClose() {
    propertyNameController.dispose();
    streetAddressController.dispose();
    baseNightlyRateController.dispose();
    cleaningFeeController.dispose();
    super.onClose();
  }
}
