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
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class AuthController extends BaseController {
  final msisdn = ''.obs;
  final errorText = Rxn<String>();
  final password = ''.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
  final hasPinEnabled = false.obs;
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
  }

  void login() async {
    if (!authFormKey.currentState!.validate()) return;

    password(passwordController.text);
    msisdn(msisdnController.text.trim());

    final connectivity = await Util().checkConnectivity();
    if (connectivity != 'Mobile' && connectivity != 'Wifi') {
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

      // First login must happen online. Offline is allowed only after PIN is configured.
      if (isFirstLogin || !hasValidPin) {
        showErrorMessage(
          _t(
            'First login requires internet. Please connect and sign in.',
            'Kuingia kwa mara ya kwanza kunahitaji intaneti. Tafadhali unganisha na uingie.',
          ),
        );
        return;
      }

      Get.offAllNamed(Routes.MAIN);
      Get.snackbar(
        _t('Offline', 'Nje ya mtandao'),
        _t('You\'re offline. Using your last session.', 'Huna mtandao. Tunatumia kipindi chako cha mwisho.'),
        duration: const Duration(seconds: 3),
      );
      return;
    }
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

  void useBiometrics() async {
    var a = await _preferenceManager.getString('userApp');
    if (a == '') {
      showErrorMessage(_t('Enter your PIN', 'Weka PIN yako'));
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
              localizedReason: _t(
                'Scan your fingerprint (or face) to login',
                'Weka alama ya kidole (au uso) ili kuingia',
              ),
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
        showErrorMessage(_t(
          'Your phone does not support biometrics... enter your password',
          'Simu yako haitumii biometria... weka nenosiri lako',
        ));
      }
    } else {
      showErrorMessage(_t(
        'Cannot access biometrics... enter your password',
        'Hatuwezi kufikia biometria... weka nenosiri lako',
      ));
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
        } else if (!hasValidPin) {
          debugPrint('PIN not configured yet: go to change pin setup');
          Get.offAllNamed(
            Routes.CHANGE_PIN,
          );
        } else {
          debugPrint('PIN exists: continue to app');
          Get.offAllNamed(Routes.MAIN, arguments: {'from_password_login': true});
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