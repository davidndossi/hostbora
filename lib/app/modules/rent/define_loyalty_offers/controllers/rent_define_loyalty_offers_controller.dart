import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_loyalty_offer_local_data_source.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';

class RentDefineLoyaltyOffersController extends BaseController {
  RentDefineLoyaltyOffersController()
      : _local = Get.find<RentLoyaltyOfferLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentLoyaltyOfferLocalDataSource _local;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
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

    final localId = await _local.insert(
      minStayMonths: minStay,
      revenueThresholdTsh: revenue,
      offerType: offerTypeLabels[selectedOfferType.value],
      terms: terms,
    );

    final offerType = offerTypeLabels[selectedOfferType.value];
    final payload = <String, dynamic>{
      'title': offerType,
      'offerType': offerType,
      'minStayMonths': minStay,
      'revenueThresholdTsh': revenue,
      'terms': terms,
      'status': 'active',
    };
    try {
      final res = await _repository.createLoyaltyOffer(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'loyalty',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'loyalty:create:$localId',
      );
      _syncWorker.runNow();
    }

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
