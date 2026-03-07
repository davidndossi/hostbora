import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class ResetPasswordController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  void goBack() => Get.back();

  void backToLogin() => Get.offAllNamed(Routes.AUTH);

  void sendCode() {
    if (formKey.currentState?.validate() ?? false) {
      // TODO: call API to send verification code to email
      // Then navigate to OTP or a "check your email" screen
      Get.toNamed(Routes.OTP, arguments: {
        'email': emailController.text.trim(),
        'flow': 'reset_password',
      });
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
