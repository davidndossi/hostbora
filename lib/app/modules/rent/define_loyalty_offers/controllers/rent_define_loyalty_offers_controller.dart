import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_loyalty_offer_local_data_source.dart';
import '../../../../routes/app_pages.dart';

class RentDefineLoyaltyOffersController extends BaseController {
  RentDefineLoyaltyOffersController()
      : _local = Get.find<RentLoyaltyOfferLocalDataSource>();

  final RentLoyaltyOfferLocalDataSource _local;
  final formKey = GlobalKey<FormState>();

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

  Future<void> onDeploy() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final minStay = int.tryParse(minStayController.text.trim());
    final revenue = double.tryParse(revenueController.text.trim().replaceAll(',', ''));
    final terms = termsController.text.trim();

    if (minStay == null || minStay <= 0) {
      showErrorMessage('Enter a valid minimum stay');
      return;
    }
    if (revenue == null || revenue <= 0) {
      showErrorMessage('Enter a valid revenue threshold');
      return;
    }
    if (terms.isEmpty) {
      showErrorMessage('Terms are required');
      return;
    }

    await _local.insert(
      minStayMonths: minStay,
      revenueThresholdTsh: revenue,
      offerType: offerTypeLabels[selectedOfferType.value],
      terms: terms,
    );

    showSuccessMessage('Loyalty offer saved offline');
  }

  /// Replace with real data: e.g. `hasActivePrograms.value = await _repo.getActiveLoyaltyProgramCount() > 0`.
  Future<void> refreshActiveProgramsPresence() async {
    await Future<void>.delayed(Duration.zero);
    hasActivePrograms.value = true;
  }

  void openActiveLoyaltyPrograms() {
    Get.toNamed(Routes.RENT_ACTIVE_LOYALTY_PROGRAMS);
  }

  String? validateMinStay(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Enter valid months';
    return null;
  }

  String? validateRevenue(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter valid amount';
    return null;
  }

  String? validateTerms(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Required';
    if (v.length < 12) return 'Please add more detail';
    return null;
  }
}
