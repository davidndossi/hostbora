import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/otp_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class OtpController extends BaseController {
  final enteredPin = <String>[].obs;
  final selectedIndex = (-1).obs;
  final otp = ''.obs;
  final isLoading = false.obs;

  final PreferenceManager _preferenceManager =
  Get.find(tag: (PreferenceManager).toString());
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  TextEditingController otpController = TextEditingController();

  // ignore: close_sinks
  StreamController<ErrorAnimationType>? errorController = StreamController<ErrorAnimationType>();

  late String msisdn;

  @override
  void onInit() async {
    msisdn = await _preferenceManager.getString('username');
    if (Get.arguments != null) {
      if (Get.arguments['msisdn'] != null) {
        String msisdn = Get.arguments['msisdn'];
        this.msisdn = msisdn;
      }
    }
    super.onInit();
  }

  void addDigit(String digit) {
    if (enteredPin.length < 4) {
      enteredPin.add(digit);
      selectedIndex(enteredPin.length - 1);
    }
  }

  void deleteDigit() {
    if (selectedIndex >= 0 && selectedIndex < enteredPin.length) {
      enteredPin.removeAt(selectedIndex.value);
      selectedIndex(enteredPin.isEmpty ? -1 : enteredPin.length - 1);
    } else if (enteredPin.isNotEmpty) {
      // If no digit selected, delete last one
      enteredPin.removeLast();
      selectedIndex(enteredPin.isEmpty ? -1 : enteredPin.length - 1);
    }
  }

  void clearAll() {
    enteredPin.clear();
    selectedIndex(-1);
  }

  void selectDigit(int index) {
    selectedIndex(index);
  }

  void _handleVerificationCodeResponseSuccess(Map<String, dynamic> res) async {
    if (res.containsKey('message') && res['message'] != null) {
      String message = res['message'];
      if (message == 'verify_code_success') {
        debugPrint('Go to home page');
        Get.offAndToNamed(AppPages.initial);
      }
    }
    showErrorMessage('Invalid OTP or code');
  }

  void _handleVerificationResponseSuccess(OtpResponse res) async {
    if (res.respCode == '0') {
      Get.until((route) => route.isFirst);
    } else {
      callDataService(
        _repository.verifyCode(OtpRequest(msisdn: msisdn, otp: otp.value)),
        onError: _handleVerificationResponseError,
        onSuccess: _handleVerificationCodeResponseSuccess,
      );
    }
  }

  void _handleVerificationResponseError(Exception e) {
    showErrorMessage('Invalid OTP or code');
  }

  void _handleResendOtpResponseError(Exception e) {
    showErrorMessage('Failed to resend OTP or code');
  }

  void validateOtp() {
    callDataService(
      _repository.verifyPhoneNumber(OtpRequest(msisdn: msisdn, otp: otp.value)),
      onError: _handleVerificationResponseError,
      onSuccess: _handleVerificationResponseSuccess,
    );
  }

  void resendOtp() {
    callDataService(
      _repository.resendOtp(OtpRequest(msisdn: msisdn, otp: otp.value)),
      onError: _handleResendOtpResponseError,
      onSuccess: (_) => showSuccessMessage('OTP resent successfully'),
    );
  }

}