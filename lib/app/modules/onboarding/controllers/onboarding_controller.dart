import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../routes/app_pages.dart';
import '../views/explanation_view.dart';

class OnboardingController extends BaseController {
  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  final PageController pageController = PageController();
  final currentPage = 0.obs;

  final List<Widget> slides = [
    ExplanationView()
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> refreshExchangeRates() async {
    final svc = Get.find<CurrencyService>();
    final ok = await svc.refreshRatesFromRemote();
    if (!ok) {
      showErrorMessage('Could not load exchange rates. You can retry in Settings.');
    }
  }

  Future<void> _markOnboardingSeen() async {
    final saved = await _preferenceManager.setBool('seen_onboarding', true);
    if (kDebugMode) {
      final readBack = await _preferenceManager.getBool(
        'seen_onboarding',
        defaultValue: false,
      );
      debugPrint(
        '[Onboarding] setBool(seen_onboarding, true) -> saved=$saved, readBack=$readBack',
      );
    }
  }

  Future<void> completeOnboarding() async {
    unawaited(Get.find<CurrencyService>().refreshRatesFromRemote());
    await _markOnboardingSeen();
    Get.offAllNamed(Routes.CREATE_HOST_ACCOUNT);
  }

  Future<void> goToLogin() async {
    unawaited(Get.find<CurrencyService>().refreshRatesFromRemote());
    await _markOnboardingSeen();
    Get.offAllNamed(Routes.AUTH);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

