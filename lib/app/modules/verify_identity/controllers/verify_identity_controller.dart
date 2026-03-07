import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class VerifyIdentityController extends BaseController {
  final codeController = TextEditingController();
  final secondsLeft = 55.obs;
  Timer? _timer;
  static const int _resendCooldownSeconds = 55;

  /// Masked email shown to user (e.g. ho***@domain.com)
  final maskedEmail = 'ho***@domain.com';

  @override
  void onReady() {
    super.onReady();
    _startTimer();
  }

  void _startTimer() {
    secondsLeft.value = _resendCooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft.value > 0) {
        secondsLeft.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  void goBack() => Get.back();

  void verify() {
    final code = codeController.text.trim();
    if (code.length != 6) return;
    // TODO: call API to verify code, then navigate on success
    Get.back(result: true);
  }

  void resendCode() {
    if (secondsLeft.value > 0) return;
    _startTimer();
    // TODO: call API to resend code
  }

  void contactSupport() => Get.toNamed(Routes.SUPPORT);

  String get timerFormatted {
    final s = secondsLeft.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  bool get canResend => secondsLeft.value <= 0;

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    super.onClose();
  }
}
