import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/service/app_review_service.dart';
import '../../../data/model/login_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/otp_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class AuthController extends BaseController {
  final msisdn = ''.obs;
  final errorText = Rxn<String>();
  final password = ''.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
  final hasPinEnabled = false.obs;
  final isPinStatusLoading = true.obs;
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;
  final authFormKey = GlobalKey<FormState>();

  final Rx<LoginResponse> _loginResponse = LoginResponse().obs;
  LoginResponse get loginResponse => _loginResponse.value;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final TextEditingController msisdnController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  late String firebaseToken;

  // ignore: close_sinks
  StreamController<ErrorAnimationType>? errorController = StreamController<ErrorAnimationType>();

  @override
  void onInit() {
    getFirebaseToken();
    _loadPinStatus();
    super.onInit();
  }

  @override
  void onClose() {
    errorController?.close();
    try {
      msisdnController.dispose();
    } catch (_) {}
    try {
      passwordController.dispose();
    } catch (_) {}
    try {
      otpController.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> _loadPinStatus() async {
    hasPinEnabled.value = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    isPinStatusLoading.value = false;
  }

  void login() async {
    if (!authFormKey.currentState!.validate()) return;

    password(passwordController.text);
    msisdn(msisdnController.text.trim());

    final pinEnabled = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    final pinCode = await _preferenceManager.getString(
      PreferenceManager.keyPinCode,
      defaultValue: '',
    );
    final isFirstLogin = await _preferenceManager.getBool(
      PreferenceManager.keyFirstLogin,
      defaultValue: true,
    );
    final hasValidPin = pinEnabled && pinCode.length == 4;
    final online = await Util.isOnline();

    // Returning users with PIN may skip server sign-in when offline.
    if (!online && !isFirstLogin && hasValidPin) {
      await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace();
      Get.snackbar(
        _t('Offline', 'Nje ya mtandao'),
        _t('You\'re offline. Using your last session.', 'Huna mtandao. Tunatumia kipindi chako cha mwisho.'),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // First login (or no PIN): always attempt server sign-in. connectivity_plus
    // can false-report offline on iPad despite active internet.
    final loginRequest = LoginRequest(
      username: msisdnController.text.trim(),
      password: passwordController.text,
      verified: true,
      firebaseToken: firebaseToken.isNotEmpty ? firebaseToken : null,
    );
    callDataService<LoginResponse>(
      _repository.signIn(loginRequest),
      onStart: () => isLoading(true),
      onComplete: () => isLoading(false),
      onError: _handleLoginResponseError,
      onSuccess: _handleLoginResponseSuccess,
    );
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  Future<void> clearPrefs() async {
    await _preferenceManager.setBool('seen_onboarding', false);
    await _preferenceManager.clear();
  }

  void _handleLoginResponseSuccess(LoginResponse res) async {
    _loginResponse(res);
    proceedToLogin(res);
  }

  void _handleLoginResponseError(Exception? e) {
    isLoading(false);
    if (e is ApiException && (e.message).isNotEmpty) {
      showErrorMessage(e.message);
    }
  }

  Future<void> showOtpDialog() async {
    otpController.clear();
    errorController?.close();
    errorController = StreamController<ErrorAnimationType>();
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.all(Radius.circular(15))),
        icon: SvgPicture.asset('images/info.svg'),
        title: Center(
          child: Text(_t(
            'Enter OTP sent to your registered phone number to continue!',
            'Weka OTP iliyotumwa kwenye namba yako iliyosajiliwa ili kuendelea!',
          ))
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: PinCodeTextField(
            appContext: context,
            pastedTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            length: 6,
            obscureText: false,
            animationType: AnimationType.fade,
            validator: (v) {
              if (v!.length < 6) {
                return appLocalization.requiredDigits;
              } else {
                return null;
              }
            },
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.underline,
              selectedColor: AppColors.colorPrimary,
              activeFillColor: Colors.black,
              inactiveColor: Colors.black54
            ),
            animationDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(
              fontSize: 20,
              height: 1.6
            ),
            backgroundColor: Colors.transparent,
            enableActiveFill: false,
            errorAnimationController: errorController,
            controller: otpController,
            keyboardType: TextInputType.number,
            onCompleted: (v) {
              validateOtp();
            },
            onChanged: (value) {
              otp(value);
            },
            beforeTextPaste: (text) {
              debugPrint('Allowing to paste $text');
              //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
              //but you can show anything you want here, like your pop up saying wrong paste format or etc
              return true;
            },
            onTap: () => {},
          )
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => getOtp(),
            child: Text(appLocalization.resend),
          ),
          TextButton(
            onPressed: () => Get.back(closeOverlays: true),
            child: Text(appLocalization.cancel),
          )
        ],
      ));
  }

  Future<void> proceedToLogin(LoginResponse res) async {
    if (res.message == 'expired_version') {
      showErrorMessage(appLocalization.expiredVersion);
    } else if (res.message == 'auth_success' || res.message == 'verify_code') {
      await Get.find<SessionService>().saveFromLogin(res);
      await _preferenceManager.setString(
          PreferenceManager.keyUsername, loginResponse.user?.msisdn ?? '');
      await _preferenceManager.setString(PreferenceManager.keyFullName,
          loginResponse.user?.fullName ?? '');

      // Kept for legacy offline unlock fallback.
      await _preferenceManager.setString('userApp', password.value);
      if (res.message == 'auth_success') {
        try {
          await Get.find<AppReviewService>().onSuccessfulLogin();
        } catch (_) {}
      }
      if (res.token != null) {
        final hasPinEnabled = await _preferenceManager.getBool(
          PreferenceManager.keyPinEnabled,
          defaultValue: false,
        );
        final storedPin = await _preferenceManager.getString(
          PreferenceManager.keyPinCode,
          defaultValue: '',
        );
        final hasValidPin = hasPinEnabled && storedPin.length == 4;

        if (res.message == 'verify_code') {
          debugPrint('Go to otp page');
          Get.offAndToNamed(Routes.OTP);
        } else         if (!hasValidPin) {
          triggerRemoteAccountSync();
          // Returning user on a new device: if this account already has a PIN
          // saved remotely, let them confirm/reuse it instead of forcing a
          // brand-new one.
          final hasRemotePin = await _hasRemotePinSet();
          debugPrint(
            'PIN not configured locally. hasRemotePin=$hasRemotePin',
          );
          Get.offAllNamed(
            Routes.CHANGE_PIN,
            arguments: {
              WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
              if (hasRemotePin) 'confirm_remote_pin': true,
            },
          );
        } else {
          debugPrint('PIN exists: continue to app');
          triggerRemoteAccountSync();
          await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace(
            arguments: {
              'from_password_login': true,
              WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
            },
          );
        }
      } else {
        showErrorMessage(appLocalization.loginFailed);
      }
    } else if (res.message == '55') {
      showErrorMessage(appLocalization.incorrectPassword);
    } else {
      showErrorMessage(appLocalization.loginFailed);
    }
  }

  /// Best-effort check of whether the server already has a PIN saved for this
  /// account. Defaults to false (first-time setup) on any error, so a flaky
  /// network call never blocks login.
  Future<bool> _hasRemotePinSet() async {
    try {
      final res = await _repository.getPinStatus();
      final data = res.data;
      return data is Map && data['hasPinSet'] == true;
    } catch (e) {
      logger.w('getPinStatus failed (non-blocking): $e');
      return false;
    }
  }

  void _handleQueryResponseError(Exception e) {}

  void _handleOtpResponseSuccess(void _) async {}

  void getOtp() {
    callDataService(
      _repository.getOtp(),
      onSuccess: _handleOtpResponseSuccess,
      onError: _handleQueryResponseError
    );
  }

  Future<void> _handleOtpValidateResponseSuccess(OtpResponse res) async {
    Get.back(closeOverlays: true);
    if (res.respCode == '0') {
      proceedToLogin(loginResponse);
    } else {
      showErrorMessage('${res.respMsg}');
    }
  }

  void validateOtp() {
    OtpRequest request = OtpRequest(
      msisdn: msisdnController.text,
      otp: otp.value
    );
    callDataService(
      _repository.verifyPhoneNumber(request),
      onSuccess: _handleOtpValidateResponseSuccess,
      onError: _handleQueryResponseError
    );
  }

  String? validator(String? value) {
    if (value != null && value.isEmpty) {
      return appLocalization.requiredField;
    }
    // Tanzanian phone number validation: starts with 0, followed by 6, 7, or 8, then 8 digits
    final phonePattern = RegExp(r'^0[678]\d{8}$');
    if (value != null && !phonePattern.hasMatch(value)) {
      return _t(
        'Please enter a valid phone number (e.g., 0612345678)',
        'Tafadhali weka namba sahihi ya simu (mf. 0612345678)',
      );
    }
    return null;
  }

  String? passwordValidator(String? value) {
    return (value ?? '').length >= 8
        ? null
        : _t('Password must be at least 8 characters', 'Nenosiri lazima liwe na angalau herufi 8');
  }

  void checkMsisdn() {
    if (msisdnController.text.isNotEmpty) {
      Get.toNamed(Routes.CHANGE_PASSWORD,
          arguments: {'msisdn': msisdnController.text});
    } else {
      errorText(_t('Please input your phone first!', 'Tafadhali weka namba yako ya simu kwanza!'));
    }
  }
}