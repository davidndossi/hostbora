import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/password_policy.dart';
import '../../../data/model/change_password_request.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class NewPasswordController extends BaseController {
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final _passwordTrigger = 0.obs;
  final isLoading = false.obs;

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  String get msisdn => Get.arguments?['msisdn']?.toString() ?? '';
  String get otp => Get.arguments?['otp']?.toString() ?? '';

  static const int step = 3;
  static const int totalSteps = 3;

  double get strength {
    _passwordTrigger.value;
    final p = newPasswordController.text;
    if (p.isEmpty) return 0;
    var met = 0;
    if (PasswordPolicy.hasMinLength(p)) met++;
    if (PasswordPolicy.hasUppercase(p)) met++;
    if (PasswordPolicy.hasLowercase(p)) met++;
    if (PasswordPolicy.hasDigit(p)) met++;
    if (PasswordPolicy.hasSpecial(p)) met++;
    if (p.length >= 12) met++;
    return (met / 6).clamp(0.0, 1.0);
  }

  String get strengthLabel {
    _passwordTrigger.value;
    if (strength >= 0.85) {
      return _t('STRONG', 'IMARA');
    }
    if (strength >= 0.65) {
      return _t('GOOD', 'NZURI');
    }
    if (strength >= 0.35) {
      return _t('FAIR', 'WASTANI');
    }
    return _t('WEAK', 'DHAIFU');
  }

  bool get hasMinLength {
    _passwordTrigger.value;
    return PasswordPolicy.hasMinLength(newPasswordController.text);
  }

  bool get hasUppercase {
    _passwordTrigger.value;
    return PasswordPolicy.hasUppercase(newPasswordController.text);
  }

  bool get hasLowercase {
    _passwordTrigger.value;
    return PasswordPolicy.hasLowercase(newPasswordController.text);
  }

  bool get hasDigit {
    _passwordTrigger.value;
    return PasswordPolicy.hasDigit(newPasswordController.text);
  }

  bool get hasSpecial {
    _passwordTrigger.value;
    return PasswordPolicy.hasSpecial(newPasswordController.text);
  }

  void goBack() => Get.back();

  void toggleNewPasswordVisibility() =>
      obscureNewPassword.value = !obscureNewPassword.value;

  void toggleConfirmPasswordVisibility() =>
      obscureConfirmPassword.value = !obscureConfirmPassword.value;

  void refreshPasswordUi() => _passwordTrigger.value++;

  void resetAndLogin() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (msisdn.isEmpty || otp.isEmpty) {
      showErrorMessage(
        _t(
          'Session expired. Please start reset password again.',
          'Kipindi kimeisha. Tafadhali anza tena kuweka upya nenosiri.',
        ),
      );
      return;
    }
    isLoading(true);
    final req = ChangePasswordRequest(
      username: msisdn,
      password: otp,
      newPassword1: newPasswordController.text,
      newPassword2: confirmPasswordController.text,
    );
    callDataService<GeneralResponse>(
      _repository.changePassword(req),
      onStart: () => isLoading(true),
      onComplete: () => isLoading(false),
      onError: (_) => isLoading(false),
      onSuccess: (GeneralResponse res) {
        isLoading(false);
        if (res.responseCode == '0' || res.responseCode == null) {
          Get.offAllNamed(Routes.PASSWORD_UPDATED);
        } else {
          showErrorMessage(
            res.message ??
                _t(
                  'Failed to update password',
                  'Imeshindikana kusasisha nenosiri',
                ),
          );
        }
      },
    );
  }

  String? validateNewPassword(String? value) =>
      PasswordPolicy.validate(value, isSw: Get.locale?.languageCode == 'sw');

  String? validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return _t(
        'Please confirm your password',
        'Tafadhali thibitisha nenosiri lako',
      );
    }
    if (value != newPasswordController.text) {
      return _t('Passwords do not match', 'Nenosiri halifanani');
    }
    return null;
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
