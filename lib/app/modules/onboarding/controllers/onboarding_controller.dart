import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/modules/onboarding/views/explanation_view.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../routes/app_pages.dart';

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

  Future<void> completeOnboarding() async {
    await _preferenceManager.setBool('seen_onboarding', true);
    Get.offAllNamed(Routes.CREATE_HOST_ACCOUNT);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

