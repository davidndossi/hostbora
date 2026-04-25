import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
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
    if (p.isEmpty) {
      return 0;
    }
    double s = 0;
    if (p.length >= 8) {
      s += 0.3;
    }
    if (p.length >= 12) {
      s += 0.2;
    }
    if (RegExp(r'[0-9]').hasMatch(p)) {
      s += 0.25;
    }
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p) ||
        RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) {
      s += 0.25;
    }
    return s.clamp(0.0, 1.0);
  }

  String get strengthLabel {
    _passwordTrigger.value;
    if (strength >= 0.75) {
      return _t('STRONG', 'IMARA');
    }
    if (strength >= 0.5) {
      return _t('GOOD', 'NZURI');
    }
    if (strength >= 0.25) {
      return _t('FAIR', 'WASTANI');
    }
    return _t('WEAK', 'DHAIFU');
  }

  bool get hasMinLength {
    _passwordTrigger.value;
    return newPasswordController.text.length >= 8;
  }

  bool get hasNumberOrSymbol {
    _passwordTrigger.value;
    return RegExp(r'[0-9]').hasMatch(newPasswordController.text) ||
        RegExp(
          r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\];'\\]''',
        ).hasMatch(newPasswordController.text);
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

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return _t('New password is required', 'Nenosiri jipya linahitajika');
    }
    if (value.length < 8) {
      return _t('At least 8 characters', 'Angalau herufi 8');
    }
    if (!RegExp(r'[0-9]').hasMatch(value) &&
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return _t('Include a number or symbol', 'Jumuisha namba au alama');
    }
    return null;
  }

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
