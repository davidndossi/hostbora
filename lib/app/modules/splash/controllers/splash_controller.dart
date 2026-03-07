import 'dart:async';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../routes/app_pages.dart';

class SplashController extends BaseController {
  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  static const Duration _splashDuration = Duration(seconds: 2);

  @override
  void onInit() {
    super.onInit();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(_splashDuration);
    try {
      final hasSeenOnboarding =
          await _preferenceManager.getBool('seen_onboarding', defaultValue: false);
      if (hasSeenOnboarding) {
        Get.offAllNamed(Routes.AUTH);
      } else {
        Get.offAllNamed(Routes.ONBOARDING);
      }
    } catch (_) {
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
