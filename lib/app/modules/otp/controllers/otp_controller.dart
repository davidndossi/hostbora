import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_otp_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/app_review_service.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';

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
  String? get channel => Get.arguments?['channel']?.toString();

  String get otpSubtitle {
    final ch = channel?.toUpperCase();
    if (ch == 'EMAIL') {
      return _t(
        'We sent a 4-digit code to your email. Enter it below.',
        'Tumetuma msimbo wa tarakimu 4 kwenye barua pepe yako. Weka hapa chini.',
      );
    }
    if (ch == 'SMS') {
      return _t(
        'We sent a 4-digit code by SMS. Enter it below.',
        'Tumetuma msimbo wa tarakimu 4 kwa SMS. Weka hapa chini.',
      );
    }
    if (flow == 'registration' || flow == 'login') {
      return _t(
        'Enter the 4-digit verification code we sent you.',
        'Weka msimbo wa uthibitisho wa tarakimu 4 tuliokutumia.',
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

  /// Returns to the previous step so the user can update phone/email.
  /// Registration / forgot-password often clear the stack (`offAllNamed`), so
  /// we navigate explicitly when [Get.back] is not available.
  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    switch (flow) {
      case 'registration':
        Get.offAllNamed(Routes.CREATE_HOST_ACCOUNT);
        break;
      case 'forgot':
      case 'forgot_password':
      case 'reset_password':
        Get.offAllNamed(Routes.RESET_PASSWORD);
        break;
      case 'login':
      default:
        Get.offAllNamed(Routes.AUTH);
        break;
    }
  }

  Future<void> _completeLogin(LoginResponse res) async {
    if (res.token == null || res.token!.isEmpty) {
      showErrorMessage(
        _t('Login failed. Please try again.', 'Kuingia kumeshindikana. Jaribu tena.'),
      );
      errorController?.add(ErrorAnimationType.shake);
      return;
    }
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().proceedToLogin(res);
      return;
    }
    // Fallback if AuthController is not in memory (e.g. deep-linked OTP).
    await Get.find<SessionService>().saveFromLogin(res);
    await _preferenceManager.setString(
      PreferenceManager.keyUsername,
      res.user?.msisdn ?? msisdn,
    );
    await _preferenceManager.setString(
      PreferenceManager.keyFullName,
      res.user?.fullName ?? '',
    );
    try {
      await Get.find<AppReviewService>().onSuccessfulLogin();
    } catch (_) {}
    triggerRemoteAccountSync();
    final hasPinEnabled = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    final storedPin = await _preferenceManager.getString(
      PreferenceManager.keyPinCode,
      defaultValue: '',
    );
    if (!hasPinEnabled || storedPin.length != 4) {
      Get.offAllNamed(Routes.CHANGE_PIN);
    } else {
      await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace();
    }
  }

  void _handleLoginOrRegistrationSuccess(LoginResponse res) {
    _completeLogin(res);
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
          _t(
            'Failed to resend OTP or code',
            'Imeshindikana kutuma tena OTP au msimbo',
          ),
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
    if (flow == 'login') {
      callDataService(
        _repository.verifyLoginOtp(
          LoginOtpRequest(msisdn: msisdn, otp: otp.value),
        ),
        onError: _handleVerificationResponseError,
        onSuccess: _handleLoginOrRegistrationSuccess,
      );
      return;
    }
    // Registration (default) — verifyPhone now returns a login session.
    callDataService(
      _repository.verifyPhoneNumber(
        OtpRequest(msisdn: msisdn, otp: otp.value),
      ),
      onError: _handleVerificationResponseError,
      onSuccess: _handleLoginOrRegistrationSuccess,
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

  void _clearOtpInput() {
    otp.value = '';
    otpController.clear();
  }

  void resendOtp() {
    // Clear any previously entered digits so the user cannot submit an
    // expired/invalid code after requesting a new one.
    _clearOtpInput();
    if (flow == 'login') {
      callDataService(
        _repository.requestLoginOtp(
          LoginOtpRequest(
            msisdn: msisdn,
            channel: channel ?? 'SMS',
          ),
        ),
        onError: _handleResendOtpResponseError,
        onSuccess: _handleResendOtpSuccess,
      );
      return;
    }
    callDataService(
      _repository.resendOtp(
        OtpRequest(
          msisdn: msisdn,
          email: email,
          flow: flow.isEmpty ? 'registration' : flow,
          channel: channel,
        ),
      ),
      onError: _handleResendOtpResponseError,
      onSuccess: _handleResendOtpSuccess,
    );
  }
}
