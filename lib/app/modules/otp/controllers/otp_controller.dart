import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/otp_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class OtpController extends BaseController {
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;
  final enteredPin = <String>[].obs;
  final selectedIndex = (-1).obs;
  final otp = ''.obs;
  final isLoading = false.obs;

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  TextEditingController otpController = TextEditingController();

  // ignore: close_sinks
  StreamController<ErrorAnimationType>? errorController =
      StreamController<ErrorAnimationType>();

  late String msisdn;
  String get flow => Get.arguments?['flow']?.toString() ?? '';
  String? get email => Get.arguments?['email']?.toString();

  String get otpSubtitle {
    if (flow == 'registration') {
      return _t(
        'We sent a verification code to your email and phone number. Enter the code below.',
        'Tumetuma msimbo wa uthibitisho kwenye barua pepe na namba yako ya simu. Weka msimbo hapa chini.',
      );
    }
    return appLocalization.otpSubtitle;
  }

  @override
  void onInit() async {
    msisdn = await _preferenceManager.getString('username');
    if (Get.arguments != null) {
      if (Get.arguments['msisdn'] != null) {
        final argMsisdn = Get.arguments['msisdn'];
        this.msisdn = argMsisdn is String ? argMsisdn : argMsisdn.toString();
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

  void _handleVerificationResponseSuccess(OtpResponse res) async {
    if (res.respCode == '0') {
      if (flow == 'reset_password') {
        Get.offAllNamed(
          Routes.NEW_PASSWORD,
          arguments: {'msisdn': msisdn, 'otp': otp.value},
        );
      } else if (flow == 'registration') {
        Get.offAllNamed(Routes.AUTH);
        showSuccessMessage(
          'Registration successful. Please sign in with your phone and password.',
        );
      } else {
        Get.until((route) => route.isFirst);
      }
      return;
    }
    // Do not fall back to /api/auth/verify — it previously skipped OTP checks.
    showErrorMessage(
      res.respMsg?.isNotEmpty == true
          ? res.respMsg!
          : _t('Invalid OTP', 'OTP si sahihi'),
    );
    errorController?.add(ErrorAnimationType.shake);
  }

  void _handleVerificationResponseError(Exception e) {
    final message = e is ApiException && e.message.isNotEmpty
        ? e.message
        : _t('Invalid OTP', 'OTP si sahihi');
    showErrorMessage(message);
    errorController?.add(ErrorAnimationType.shake);
  }

  void _handleResendOtpResponseError(Exception e) {
    final message = e is ApiException && e.message.isNotEmpty
        ? e.message
        : _t(
            'Failed to resend OTP or code',
            'Imeshindikana kutuma tena OTP au msimbo',
          );
    showErrorMessage(message);
  }

  void _handleResendOtpSuccess(GeneralResponse res) {
    if (res.responseCode == '0' || res.responseCode == null) {
      showSuccessMessage(
        _t('OTP resent successfully', 'OTP imetumwa tena kwa mafanikio'),
      );
      return;
    }
    showErrorMessage(
      res.message ??
          _t('Failed to resend OTP or code', 'Imeshindikana kutuma tena OTP au msimbo'),
    );
  }

  void validateOtp() {
    if (flow == 'reset_password') {
      callDataService(
        _repository.verifyForgotOtp(OtpRequest(msisdn: msisdn, otp: otp.value)),
        onError: _handleVerificationResponseError,
        onSuccess: _handleVerifyForgotOtpSuccess,
      );
      return;
    }
    callDataService(
      _repository.verifyPhoneNumber(OtpRequest(msisdn: msisdn, otp: otp.value)),
      onError: _handleVerificationResponseError,
      onSuccess: _handleVerificationResponseSuccess,
    );
  }

  void _handleVerifyForgotOtpSuccess(GeneralResponse res) {
    if (res.responseCode == '0' || res.responseCode == null) {
      Get.offAllNamed(
        Routes.NEW_PASSWORD,
        arguments: {'msisdn': msisdn, 'otp': otp.value},
      );
    } else {
      showErrorMessage(
        res.message ??
            _t('Invalid or expired OTP', 'OTP si sahihi au muda wake umeisha'),
      );
    }
  }

  void resendOtp() {
    callDataService(
      _repository.resendOtp(
        OtpRequest(
          msisdn: msisdn,
          email: email,
          flow: flow.isEmpty ? 'registration' : flow,
        ),
      ),
      onError: _handleResendOtpResponseError,
      onSuccess: _handleResendOtpSuccess,
    );
  }
}