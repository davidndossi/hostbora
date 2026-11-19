import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/utils/auth_messages.dart';
import '../../../core/utils/referral_link.dart';
import '../../../core/utils/util.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/otp_request.dart';
import '../../../data/model/reg_request.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/analytics_service.dart';
import '../../../data/service/app_review_service.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';

/// Ordered steps of the sign-up wizard. One question per screen so the
/// progress bar can advance on every answer — the whole point of the goal
/// gradient is that the host sees the remaining distance shrink.
enum SignupStep { name, phone, email, code }

class CreateHostAccountController extends BaseController {
  /// One form wraps the whole wizard. Only the current step's fields are ever
  /// mounted, so [FormState.validate] naturally scopes itself to that step —
  /// and there is no per-step GlobalKey to collide during the transition.
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final referralCodeController = TextEditingController();
  final otpController = TextEditingController();

  final step = SignupStep.name.obs;

  /// True while the register or verify call is in flight. Both block the
  /// primary button, so a double tap cannot register twice.
  final isLoading = false.obs;

  /// Step 3 answer. Null until the host picks: an email is genuinely optional,
  /// and plenty of hosts here manage property on a phone number alone.
  final hasEmail = Rxn<bool>();

  /// Whether a referral code is in play. Set only from a referral deep link
  /// in [onInit] — the host is never asked.
  ///
  /// Asking cost a whole step to collect something a host without a code
  /// cannot answer usefully and a host with one does not need to type: the
  /// link already carries it. Kept as an [Rxn] rather than a plain bool so
  /// [_answersSignature] keeps its three-state meaning.
  final wasReferred = Rxn<bool>();

  /// Without an email there is nowhere to send a code but SMS, so the code
  /// step must not offer the switch.
  bool get canUseEmailChannel =>
      hasEmail.value == true && emailController.text.trim().isNotEmpty;

  final referralValid = Rxn<bool>();
  final referralAgentName = RxnString();
  final isCheckingReferral = false.obs;
  Timer? _referralDebounce;

  final msisdn = ''.obs;
  final email = ''.obs;

  /// Channel the code was actually sent on, so the code step can name it and
  /// offer the other one.
  final channel = 'SMS'.obs;

  /// Set once registration succeeds. Going back from the code step must not
  /// register a second time with the same phone number.
  final registered = false.obs;

  /// The answers the account was actually registered with. Stepping back and
  /// forward with nothing changed returns to the code screen instead of
  /// calling register again, which would fail with "already exists".
  String _registeredSignature = '';

  String get _answersSignature => [
        phoneController.text.trim(),
        hasEmail.value == true ? emailController.text.trim() : '',
        wasReferred.value == true ? referralCodeController.text.trim() : '',
      ].join('|');

  static const int resendCooldownSeconds = 60;
  final secondsLeft = 0.obs;
  final isResending = false.obs;
  Timer? _resendTimer;

  bool get canResend => secondsLeft.value <= 0 && !isResending.value;

  String get resendCooldownLabel {
    final s = secondsLeft.value;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t(String en, String sw) => _isSw ? sw : en;

  // ── Progress ──────────────────────────────────────────────────────────────

  List<SignupStep> get steps => SignupStep.values;

  int get stepIndex => steps.indexOf(step.value);

  int get totalSteps => steps.length;

  /// Drives the progress bar. Deliberately reports the *completed* fraction of
  /// the current step as already banked, so step one does not read as 0%.
  double get progress => (stepIndex + 1) / totalSteps;

  String get firstName => firstNameController.text.trim();

  @override
  void onInit() {
    super.onInit();
    final code = ReferralLinks.pendingCode;
    if (code != null && code.isNotEmpty) {
      // Arrived from a referral deep link: the answer to "were you referred"
      // is already known, so skip asking and just show the prefilled code.
      referralCodeController.text = code;
      wasReferred.value = true;
      scheduleReferralHint();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Validates the current step and advances, registering the account when
  /// the email step is answered (that call is what sends the code).
  Future<void> next() async {
    if (isLoading.value) return;
    switch (step.value) {
      case SignupStep.name:
        if (formKey.currentState?.validate() != true) return;
        step.value = SignupStep.phone;
        return;
      case SignupStep.phone:
        if (formKey.currentState?.validate() != true) return;
        step.value = SignupStep.email;
        return;
      case SignupStep.email:
        if (hasEmail.value == null) {
          showErrorMessage(
            _t('Pick one to continue', 'Chagua moja ili kuendelea'),
          );
          return;
        }
        if (formKey.currentState?.validate() != true) return;
        // Registration moved here from the dropped referral step: this is now
        // the last question, and registering is what sends the code.
        if (registered.value && _answersSignature == _registeredSignature) {
          step.value = SignupStep.code;
          return;
        }
        await _register();
        return;
      case SignupStep.code:
        await verifyCode();
        return;
    }
  }

  /// Steps back, leaving the stack when there is nowhere left to go.
  void back() {
    switch (step.value) {
      case SignupStep.name:
        if (Get.key.currentState?.canPop() ?? false) {
          Get.back();
        } else {
          Get.offAllNamed(Routes.AUTH);
        }
        return;
      case SignupStep.phone:
        step.value = SignupStep.name;
        return;
      case SignupStep.email:
        step.value = SignupStep.phone;
        return;
      case SignupStep.code:
        // Earlier answers stay editable: coming forward again with the same
        // ones returns here without re-registering, and a changed phone
        // number registers a genuinely different account.
        step.value = SignupStep.email;
        return;
    }
  }

  void setHasEmail(bool value) {
    hasEmail.value = value;
    if (!value) {
      emailController.clear();
      // Nothing to reach them at but the phone, so pin the channel back to
      // SMS in case they had already switched it on the code step.
      channel.value = 'SMS';
    }
  }

  void goToLogin() => Get.offAllNamed(Routes.AUTH);

  void goToTerms() => Get.toNamed(Routes.TERMS);

  void goToPrivacy() => Get.toNamed(Routes.PRIVACY);

  // ── Referral hint ─────────────────────────────────────────────────────────

  /// Optional hint only. Signup never waits for this; the server attaches
  /// the code after OTP verify on a background thread.
  void scheduleReferralHint() {
    _referralDebounce?.cancel();
    final code = referralCodeController.text.trim();
    if (code.isEmpty) {
      referralValid.value = null;
      referralAgentName.value = null;
      isCheckingReferral.value = false;
      return;
    }
    _referralDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(validateReferralCode());
    });
  }

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

  // ── Registration ──────────────────────────────────────────────────────────

  /// Sends the registration, which is also what dispatches the 4-digit code.
  Future<void> _register() async {
    if (!await Util.isOnline()) {
      showErrorMessage(appLocalization.noInternet);
      return;
    }

    final msisdnValue = phoneController.text.trim();
    final emailStr =
        hasEmail.value == true ? emailController.text.trim() : '';
    msisdn(msisdnValue);
    email(emailStr);
    if (emailStr.isEmpty) channel.value = 'SMS';

    final referralCode = wasReferred.value == true
        ? referralCodeController.text.trim()
        : '';

    final regRequest = RegRequest(
      firstName: firstName,
      surname: lastNameController.text.trim().isEmpty
          ? null
          : lastNameController.text.trim(),
      mobileNumber: msisdnValue,
      email: emailStr.isEmpty ? null : emailStr,
      channel: channel.value,
      referralCode: referralCode.isEmpty ? null : referralCode,
    );

    await _preferenceManager.setString(
      PreferenceManager.keyUsername,
      msisdnValue,
    );
    await _preferenceManager.setString(
      PreferenceManager.keySignupFirstName,
      firstName,
    );

    callDataService<GeneralResponse>(
      _repository.createUserProfile(regRequest),
      onStart: () => isLoading(true),
      onComplete: () => isLoading(false),
      onError: _handleRegistrationError,
      onSuccess: _handleRegistrationSuccess,
    );
  }

  void _handleRegistrationError(Exception? e) {
    isLoading(false);
    if (e is! ApiException || e.message.isEmpty) return;
    final message = _registrationErrorMessage(e.message);
    if (e.message.toLowerCase().contains('already exists')) {
      Get.snackbar(
        _t('Account exists', 'Akaunti ipo'),
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: goToLogin,
          child: Text(
            _t('Sign in', 'Ingia'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }
    showErrorMessage(message);
  }

  /// The API returns this when the mail provider rejects the recipient.
  String _registrationErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email otp') || lower.contains('failed to send email')) {
      return _t(
        'That email address could not receive a code. Use a different email, or choose SMS.',
        'Hatukuweza kutuma msimbo kwenye barua pepe hiyo. Tumia barua pepe nyingine, au chagua SMS.',
      );
    }
    return message;
  }

  void _handleRegistrationSuccess(GeneralResponse res) {
    isLoading(false);
    if (res.responseCode != '0' && res.responseCode != null) {
      showErrorMessage(res.message ?? appLocalization.loginFailed);
      return;
    }
    analytics?.logSignUp(
      method: channel.value,
      usedReferralCode: referralCodeController.text.trim().isNotEmpty,
    );
    registered.value = true;
    _registeredSignature = _answersSignature;
    otpController.clear();
    _startResendCooldown();
    step.value = SignupStep.code;
  }

  // ── Code entry ────────────────────────────────────────────────────────────

  void onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return;
    unawaited(verifyCode());
  }

  Future<void> verifyCode() async {
    if (isLoading.value) return;
    final code = otpController.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 4) {
      showErrorMessage(
        _t('Enter the 4-digit code', 'Weka msimbo wa tarakimu 4'),
      );
      return;
    }
    isLoading(true);
    try {
      final res = await _repository
          .verifyPhoneNumber(OtpRequest(msisdn: msisdn.value, otp: code))
          .timeout(const Duration(seconds: 25));
      await _completeSignup(res);
    } on TimeoutException {
      showErrorMessage(
        _t(
          'Could not verify the code. Try again.',
          'Imeshindikana kuthibitisha msimbo. Jaribu tena.',
        ),
      );
    } on ApiException catch (e) {
      showErrorMessage(
        e.message.isNotEmpty ? e.message : _t('Invalid OTP', 'OTP si sahihi'),
      );
    } catch (_) {
      showErrorMessage(_t('Invalid OTP', 'OTP si sahihi'));
    } finally {
      isLoading(false);
    }
  }

  /// Flags the first-property step, then hands the session to the normal
  /// post-login path so PIN setup and workspace routing stay in one place.
  Future<void> _completeSignup(LoginResponse res) async {
    if (res.token == null || res.token!.isEmpty) {
      showErrorMessage(
        isMissingAccountError(res.message)
            ? missingAccountLoginMessage()
            : _t(
                'Login failed. Please try again.',
                'Kuingia kumeshindikana. Jaribu tena.',
              ),
      );
      return;
    }

    // Written before navigation so whichever screen comes next (PIN setup for
    // a brand-new account) can hand off to the first-property step.
    await _preferenceManager.setBool(
      PreferenceManager.keyPendingFirstProperty,
      true,
    );

    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().proceedToLogin(res);
      return;
    }
    await _fallbackLogin(res);
  }

  /// Used when AuthController is not in memory (sign-up reached by deep link).
  Future<void> _fallbackLogin(LoginResponse res) async {
    await Get.find<SessionService>().saveFromLogin(res);
    if (Get.isRegistered<AppLocaleController>()) {
      await Get.find<AppLocaleController>().syncWithAccount();
    }
    await _preferenceManager.setString(
      PreferenceManager.keyUsername,
      res.user?.msisdn ?? msisdn.value,
    );
    await _preferenceManager.setString(
      PreferenceManager.keyFullName,
      res.user?.fullName ?? '',
    );
    try {
      await Get.find<AppReviewService>().onSuccessfulLogin();
    } catch (_) {}
    triggerRemoteAccountSync();
    // Straight to the first property, even with no PIN set. Setting one was
    // the last step of sign-up, protecting a database that did not have a row
    // in it yet; the launch router now asks once the host has a property.
    Get.offAllNamed(Routes.FIRST_PROPERTY);
  }

  // ── Resend ────────────────────────────────────────────────────────────────

  void _startResendCooldown() {
    secondsLeft.value = resendCooldownSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft.value > 0) {
        secondsLeft.value--;
      } else {
        _resendTimer?.cancel();
        _resendTimer = null;
      }
    });
  }

  /// Resends on the current channel, or switches channel when [onChannel] is
  /// given (the code screen offers email as an alternative to SMS).
  Future<void> resendCode({String? onChannel}) async {
    if (onChannel?.toUpperCase() == 'EMAIL' && !canUseEmailChannel) return;
    final switching = onChannel != null && onChannel != channel.value;
    if (!switching && !canResend) {
      if (secondsLeft.value > 0) {
        showErrorMessage(
          _t(
            'Please wait $resendCooldownLabel before requesting another code.',
            'Tafadhali subiri $resendCooldownLabel kabla ya kuomba msimbo mwingine.',
          ),
        );
      }
      return;
    }
    if (onChannel != null) channel.value = onChannel;
    otpController.clear();
    isResending.value = true;
    _startResendCooldown();
    callDataService<GeneralResponse>(
      _repository.resendOtp(
        OtpRequest(
          msisdn: msisdn.value,
          email: email.value.isEmpty ? null : email.value,
          flow: 'registration',
          channel: channel.value,
        ),
      ),
      onError: (e) {
        isResending.value = false;
        _resendTimer?.cancel();
        _resendTimer = null;
        secondsLeft.value = 0;
        showErrorMessage(
          e is ApiException && e.message.isNotEmpty
              ? e.message
              : _t(
                  'Failed to resend the code',
                  'Imeshindikana kutuma tena msimbo',
                ),
        );
      },
      onSuccess: (res) {
        isResending.value = false;
        if (res.responseCode == '0' || res.responseCode == null) {
          showSuccessMessage(
            _t('Code sent again', 'Msimbo umetumwa tena'),
          );
          return;
        }
        _resendTimer?.cancel();
        _resendTimer = null;
        secondsLeft.value = 0;
        showErrorMessage(
          res.message ??
              _t('Failed to resend the code', 'Imeshindikana kutuma tena msimbo'),
        );
      },
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static final _nameRegex =
      RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ\s'\-]{0,118}$");

  String? validateFirstName(String? value) =>
      _validateNamePart(value, _t('First name', 'Jina la kwanza'));

  String? validateLastName(String? value) =>
      _validateNamePart(value, _t('Last name', 'Jina la familia'));

  String? _validateNamePart(String? value, String label) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return _t('$label is required', '$label linahitajika');
    }
    if (!_nameRegex.hasMatch(name)) {
      return _t(
        'Use letters, spaces, hyphens, or apostrophes only',
        'Tumia herufi, nafasi, (-) au (\') pekee',
      );
    }
    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return _t('Phone number is required', 'Namba ya simu inahitajika');
    }
    if (!RegExp(r'^0[678]\d{8}$').hasMatch(phone)) {
      return _t(
        'Enter a valid phone number (e.g. 0712345678)',
        'Weka namba sahihi ya simu (mf. 0712345678)',
      );
    }
    return null;
  }

  /// Only enforced once the host says they have one. Answering "No" leaves the
  /// field unmounted, so this is never reached in that case.
  String? validateEmail(String? value) {
    if (hasEmail.value != true) return null;
    final mail = value?.trim() ?? '';
    if (mail.isEmpty) {
      return _t('Enter your email', 'Weka barua pepe yako');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(mail)) {
      return _t('Enter a valid email', 'Weka barua pepe sahihi');
    }
    return null;
  }

  @override
  void onClose() {
    _referralDebounce?.cancel();
    _resendTimer?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    referralCodeController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
