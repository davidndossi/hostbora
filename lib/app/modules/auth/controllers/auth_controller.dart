import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/community.dart';
import '../../../data/model/login_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/otp_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class AuthController extends BaseController {
  final msisdn = ''.obs;
  final errorText = Rxn<String>();
  final password = ''.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
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

  void login() async {
    String firebaseToken = await _preferenceManager.getString(
        PreferenceManager.keyFirebaseToken);
    Util().checkConnectivity().then((value) async {
      if (value == 'Mobile' || value == 'Wifi') {
        password(passwordController.text);
        msisdn(msisdnController.text);
        LoginRequest loginRequest = LoginRequest(
          username: msisdn.value,
          password: password.value,
          verified: true,
          firebaseToken: firebaseToken
        );
        callDataService(
          _repository.signIn(loginRequest),
          onError: _handleLoginResponseError,
          onSuccess: _handleLoginResponseSuccess,
        );
      } else {
        showErrorMessage(appLocalization.noInternet);
      }
    });
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  void _handleLoginResponseSuccess(LoginResponse res) async {
    _loginResponse(res);
    proceedToLogin(res);
  }

  void _handleLoginResponseError(Exception e) {
    // showErrorMessage(e.toString());
  }

  void useBiometrics() async {
    var a = await _preferenceManager.getString('userApp');
    if (a == '') {
      showErrorMessage('Enter your PIN');
      return;
    }
    final LocalAuthentication auth = LocalAuthentication();
    // final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    // final bool canAuthenticate =
    //     canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
    if (availableBiometrics.isNotEmpty) {
      // Some biometrics are enrolled.
      if (availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.weak) ||
          availableBiometrics.contains(BiometricType.fingerprint) ||
          availableBiometrics.contains(BiometricType.face)) {
        // Specific types of biometrics are available.
        // Use checks like this with caution!
        try {
          final bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Scan your fingerprint (or face) to login',
              options: const AuthenticationOptions(
                biometricOnly: true,
                stickyAuth: true,
              )
          );
          if (didAuthenticate) {
            password(a.toString());
          } else {
            Get.back();
          }
        } on PlatformException catch (e) {
          if (e.code == auth_error.notAvailable) {
            // Add handling of no hardware here.
          } else if (e.code == auth_error.notEnrolled) {
            // ...
          } else {
            // ...
          }
        }
      } else {
        showErrorMessage('Your phone does not support biometrics... enter your password');
      }
    } else {
      showErrorMessage('Cannot access biometrics... enter your password');
    }
    // return canAuthenticate;
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
        title: const Center(
          child: Text('Enter OTP sent to your registered phone number to continue!')
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
      final expiresIn = res.expiresIn ?? 0;
      final expiryTime = DateTime.now().add(Duration(minutes: expiresIn)).toIso8601String();
      await _preferenceManager.setString(
          PreferenceManager.keyToken, loginResponse.token!);
      await _preferenceManager.setString(
          PreferenceManager.keyExpiryTime, expiryTime);
      await _preferenceManager.setString(
          PreferenceManager.keyUsername, loginResponse.user?.msisdn ?? '');
      await _preferenceManager.setString(PreferenceManager.keyFullName,
          loginResponse.user?.fullName ?? '');
      await _preferenceManager.setBool('isLeader', loginResponse.user?.isLeader ?? false);
      await _preferenceManager.setBool('isAdmin', loginResponse.user?.isAdmin ?? false);
      if (res.user != null && res.user!.communities != null) {
        final List<Community> communities = (res.user!.communities as List)
            .map((e) => Community.fromJson(e as Map<String, dynamic>))
            .toList();
        _preferenceManager.saveUserCommunities(communities);
      }

      await _preferenceManager.setUser('user', loginResponse.user);
      await _preferenceManager.setString('userApp', password.value);
      if (res.token != null) {
        _preferenceManager.setBool(PreferenceManager.keyFirstLogin, false);
        if (Navigator.canPop(Get.context!)) {
          debugPrint('Go back to previous page');
          Navigator.pop(Get.context!);
        } else {
          if (res.message == 'verify_code') {
            debugPrint('Go to otp page');
            Get.offAndToNamed(Routes.OTP);
          } else {
            debugPrint('Go to welcome back');
            Get.offAllNamed(Routes.WELCOME_BACK, arguments: {'from_password_login': true});
          }
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
      return 'Please enter a valid phone number (e.g., 0612345678)';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    return (value ?? '').length >= 8 ? null : 'Password must be at least 8 characters';
  }

  void checkMsisdn() {
    if (msisdnController.text.isNotEmpty) {
      Get.toNamed(Routes.CHANGE_PASSWORD,
          arguments: {'msisdn': msisdnController.text});
    } else {
      errorText('Please input your phone first!');
    }
  }
}