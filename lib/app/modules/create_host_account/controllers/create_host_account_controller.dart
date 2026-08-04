import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/password_policy.dart';
import '../../../core/utils/util.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/reg_request.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class CreateHostAccountController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final referralCodeController = TextEditingController();
  final obscurePassword = true.obs;
  final isLoading = false.obs;
  final referralValid = Rxn<bool>();
  final referralAgentName = RxnString();
  final isCheckingReferral = false.obs;
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

  Future<void> validateReferralCode() async {
    final code = referralCodeController.text.trim();
    referralValid.value = null;
    referralAgentName.value = null;
    if (code.isEmpty) return;

    isCheckingReferral(true);
    try {
      final res = await _repository.validateReferralCode(code);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final validation = ReferralValidation.fromJson(data);
        referralValid.value = validation.valid;
        referralAgentName.value = validation.agentName;
      } else {
        referralValid.value = false;
      }
    } catch (_) {
      referralValid.value = false;
    } finally {
      isCheckingReferral(false);
    }
  }

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
        referralCode: referralCodeController.text.trim().isEmpty
            ? null
            : referralCodeController.text.trim(),
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
      final message = e.message;
      final alreadyExists = message.toLowerCase().contains('already exists');
      if (alreadyExists) {
        Get.snackbar(
          _isSw ? 'Akaunti ipo' : 'Account exists',
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: goToLogin,
            child: Text(
              _isSw ? 'Ingia' : 'Sign in',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else {
        showErrorMessage(message);
      }
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

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return _isSw ? 'Jina kamili linahitajika' : 'Full name is required';
    }
    // Letters (incl. accented), spaces, apostrophes, hyphens only
    final nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ\s'\-]{1,118}$");
    if (!nameRegex.hasMatch(name)) {
      return _isSw
          ? 'Jina linaweza kuwa na herufi, nafasi, (-) au (\') pekee'
          : 'Name may only contain letters, spaces, hyphens, or apostrophes';
    }
    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return _isSw ? 'Namba ya simu inahitajika' : 'Phone number is required';
    }
    // Tanzanian mobile: 0 then 6/7/8, then 8 digits (e.g. 0712345678)
    final phoneRegex = RegExp(r'^0[678]\d{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      return _isSw
          ? 'Weka namba sahihi ya simu (mf. 0712345678)'
          : 'Enter a valid phone number (e.g. 0712345678)';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _isSw ? 'Barua pepe inahitajika' : 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return _isSw ? 'Weka barua pepe sahihi' : 'Enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) =>
      PasswordPolicy.validate(value, isSw: _isSw);

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
