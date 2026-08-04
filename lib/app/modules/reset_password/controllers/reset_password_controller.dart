import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class ResetPasswordController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final msisdnController = TextEditingController();
  final isLoading = false.obs;

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  String? validateMsisdn(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final phonePattern = RegExp(r'^0[678]\d{8}$');
    if (!phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g. 0712345678)';
    }
    return null;
  }

  void goBack() => Get.back();

  void backToLogin() => Get.offAllNamed(Routes.AUTH);

  Future<void> sendCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final msisdn = msisdnController.text.trim();
    if (!await Util.isOnline()) {
      showErrorMessage(appLocalization.noInternet);
      return;
    }
    isLoading(true);
    callDataService<GeneralResponse>(
      _repository.getOtpForgotPassword(OtpRequest(msisdn: msisdn)),
      onStart: () => isLoading(true),
      onComplete: () => isLoading(false),
      onError: (e) {
        isLoading(false);
        final message = e is ApiException && e.message.isNotEmpty
            ? e.message
            : 'Failed to send code. Please try again.';
        showErrorMessage(message);
      },
      onSuccess: (GeneralResponse res) {
        if (res.responseCode == '0' || res.responseCode == null) {
          Get.offAllNamed(Routes.OTP, arguments: {
            'msisdn': msisdn,
            'flow': 'reset_password',
          });
        } else {
          showErrorMessage(res.message ?? 'Failed to send code');
        }
      },
    );
  }

  @override
  void onClose() {
    msisdnController.dispose();
    super.onClose();
  }
}
