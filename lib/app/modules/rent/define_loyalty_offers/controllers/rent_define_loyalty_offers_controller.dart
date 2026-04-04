import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

class RentDefineLoyaltyOffersController extends BaseController {
  final minStayController = TextEditingController(text: '12');
  final revenueController = TextEditingController(text: '5,000,000');
  final termsController = TextEditingController();

  final selectedOfferType = 0.obs;

  final hasActivePrograms = true.obs;

  static const offerTypeLabels = <String>[
    'Reduced Rent',
    'Waived Service Charge',
    'One-time Free Maintenance',
    'Cashback/Payment',
  ];

  @override
  void onInit() {
    super.onInit();
    termsController.text =
        'Ex: Resident receives a 10% reduction on the 13th month\'s rent upon successful completion of a 12-month lease cycle without arrears.';
  }

  @override
  void onReady() {
    super.onReady();
    refreshActiveProgramsPresence();
  }

  @override
  void onClose() {
    minStayController.dispose();
    revenueController.dispose();
    termsController.dispose();
    super.onClose();
  }

  void onViewStrategyGuide() {}

  void onDiscardDraft() {
    Get.back();
  }

  void onDeploy() {
    showSuccessMessage('Loyalty program deployed');
  }

  /// Replace with real data: e.g. `hasActivePrograms.value = await _repo.getActiveLoyaltyProgramCount() > 0`.
  Future<void> refreshActiveProgramsPresence() async {
    await Future<void>.delayed(Duration.zero);
    hasActivePrograms.value = true;
  }

  void openActiveLoyaltyPrograms() {
    Get.toNamed(Routes.RENT_ACTIVE_LOYALTY_PROGRAMS);
  }
}
