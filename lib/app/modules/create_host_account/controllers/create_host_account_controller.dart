import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/reg_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class CreateHostAccountController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final msisdn = ''.obs;
  final email = ''.obs;

  late String firebaseToken;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final Rx<GeneralResponse> _generalResponse = GeneralResponse().obs;
  GeneralResponse get generalResponse => _generalResponse.value;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void goBack() => Get.back();

  void goToLogin() => Get.offAllNamed(Routes.AUTH);

  void goToTerms() => Get.toNamed(Routes.TERMS);

  void goToPrivacy() => Get.toNamed(Routes.PRIVACY);

  void signUp() async {
    if (!formKey.currentState!.validate()) return;

    String name = fullNameController.text.trim();
    String firstName = '';
    String middleName = '';
    String lastName = '';
    List<String> names = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
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
    String msisdnValue = phoneController.text.trim();
    String emailStr = emailController.text.trim();
    msisdn(msisdnValue);
    email(emailStr);
    String password = passwordController.text;

    if (!await Util.isOnline()) {
      showErrorMessage(appLocalization.noInternet);
      return;
    }
    RegRequest regRequest = RegRequest(
        firstName: firstName,
        middleName: middleName.isEmpty ? null : middleName,
        surname: lastName.isEmpty ? null : lastName,
        mobileNumber: msisdnValue,
        email: emailStr.isEmpty ? null : emailStr,
        password: password,
      );
      _preferenceManager.setString(PreferenceManager.keyUsername, msisdnValue);
      callDataService<GeneralResponse>(
        _repository.createUserProfile(regRequest),
        // onStart: () => isLoading(true),
        // onComplete: () => isLoading(false),
        onError: _handleRegistrationResponseError,
        onSuccess: _handleRegistrationResponseSuccess,
      );
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(
      PreferenceManager.keyFirebaseToken,
    );
  }

  void _handleRegistrationResponseError(Exception? e) {
    isLoading(false);
    if (e is ApiException && e.message.isNotEmpty) {
      showErrorMessage(e.message);
    }
  }

  void _handleRegistrationResponseSuccess(GeneralResponse res) async {
    _generalResponse(res);
    isLoading(false);
    if (res.responseCode == '0' || res.responseCode == null) {
      Get.offAllNamed(
        Routes.OTP,
        arguments: {
          'msisdn': msisdn.value,
          'email': email.value,
          'flow': 'registration',
        },
      );
    } else {
      showErrorMessage(res.message ?? appLocalization.loginFailed);
    }
  }

  String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
