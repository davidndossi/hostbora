import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/otp_response.dart';
import '../../../data/model/reg_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class RegistrationController extends BaseController {
  final name = ''.obs;
  final msisdn = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final selectedGender = ''.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
  final registerFormKey = GlobalKey<FormState>();

  final Rx<GeneralResponse> _generalResponse = GeneralResponse().obs;
  GeneralResponse get generalResponse => _generalResponse.value;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final TextEditingController nameController = TextEditingController();
  final TextEditingController msisdnController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
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
    msisdnController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }

  void register() async {
    if (!registerFormKey.currentState!.validate()) return;

    String name = nameController.text.trim();
    String firstName = '';
    String middleName = '';
    String lastName = '';
    List<String> names = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (names.length >= 3) {
      firstName = names[0];
      middleName = names[1];
      lastName = names.sublist(2).join(' ');
    } else if (names.length == 2) {
      firstName = names[0];
      lastName = names[1];
    } else if (names.isNotEmpty) {
      firstName = names[0];
    }
    String msisdn = msisdnController.text.trim();
    String emailStr = emailController.text.trim();
    this.msisdn(msisdn);
    this.email(emailStr);
    String password = passwordController.text;

    Util().checkConnectivity().then((value) async {
      if (value != 'Mobile' && value != 'Wifi') {
        showErrorMessage(appLocalization.noInternet);
        return;
      }
      RegRequest regRequest = RegRequest(
        firstName: firstName,
        middleName: middleName.isEmpty ? null : middleName,
        surname: lastName.isEmpty ? null : lastName,
        mobileNumber: msisdn,
        gender: selectedGender.value.isEmpty ? null : selectedGender.value,
        email: emailStr.isEmpty ? null : emailStr,
        password: password,
      );
      _preferenceManager.setString(PreferenceManager.keyUsername, msisdn);
      callDataService<GeneralResponse>(
        _repository.createUserProfile(regRequest),
        onStart: () => isLoading(true),
        onComplete: () => isLoading(false),
        onError: _handleRegistrationResponseError,
        onSuccess: _handleRegistrationResponseSuccess,
      );
    });
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  void _handleRegistrationResponseSuccess(GeneralResponse res) async {
    _generalResponse(res);
    isLoading(false);
    if (res.responseCode == '0' || res.responseCode == null) {
      Get.offAllNamed(Routes.OTP, arguments: {
        'msisdn': msisdn.value,
        'email': email.value,
        'flow': 'registration',
      });
    } else {
      showErrorMessage(res.message ?? appLocalization.loginFailed);
    }
  }

  void _handleRegistrationResponseError(Exception? e) {
    isLoading(false);
    if (e is ApiException && e.message.isNotEmpty) {
      showErrorMessage(e.message);
    }
  }

  Future<void> showOtpDialog() async {
    otpController = TextEditingController();
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
    } else if (res.message == 'success') {
      Get.offAndToNamed(AppPages.initial);
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
      Get.offAllNamed(Routes.AUTH);
      showSuccessMessage('Registration successful. Please sign in with your phone and password.');
    } else {
      showErrorMessage(res.respMsg ?? 'Verification failed');
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

  String? nameValidator(String? value) {
    if (value != null && value.isEmpty) {
      return appLocalization.requiredField;
    }
    // Check if value has at least 2 words (separated by spaces)
    final words = value?.trim().split(RegExp(r'\s+')) ?? [];
    if (words.length < 2) {
      return 'Please enter at least two names (first name and last name)';
    }
    // Check if each word has at least 2 characters
    for (var word in words) {
      if (word.length < 2) {
        return 'Each name must be at least 2 characters long';
      }
    }
    return null;
  }

  String? msisdnValidator(String? value) {
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

  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    return (value ?? '').length >= 8 ? null : 'Password must be at least 8 characters';
  }
}