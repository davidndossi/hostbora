import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/access/sales_agent_session.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/utils/auth_messages.dart';
import '../../../core/utils/util.dart';
import '../../../core/widget/otp_channel_sheet.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/service/app_review_service.dart';
import '../../../data/model/login_otp_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/base_exception.dart';
import '../../../network/exceptions/not_found_exception.dart';
import '../../../routes/app_pages.dart';

class AuthController extends BaseController {
  final msisdn = ''.obs;
  final errorText = Rxn<String>();
  final isLoading = false.obs;
  final hasPinEnabled = false.obs;
  final isPinStatusLoading = true.obs;
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  String _loginAccessMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('revoked') || lower.contains('account locked')) {
      return _t(
        'Your access has been revoked. Contact your property owner.',
        'Ufikiaji wako umeondolewa. Wasiliana na mmiliki wa mali.',
      );
    }
    return raw;
  }
  /// Static so the key outlives fenix recreation of this controller.
  ///
  /// As an instance field it was replaced every time GetX rebuilt the
  /// controller, while the already-mounted [Form] in AuthView kept the old
  /// one — so the new key pointed at no element and `currentState` was null.
  /// There is only ever one AuthView mounted, so one key for it is correct;
  /// and because the controller is a Get singleton, every AuthView already
  /// shared this key before it was made static.
  static final authFormKey = GlobalKey<FormState>();

  final Rx<LoginResponse> _loginResponse = LoginResponse().obs;
  LoginResponse get loginResponse => _loginResponse.value;

  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  /// Owned by the login form; do not dispose in [onClose] — Auth can stay
  /// under OTP / Create Account while GetX briefly drops this controller
  /// (fenix), which would leave TextFormField attached to a disposed TEC.
  TextEditingController msisdnController = TextEditingController();

  late String firebaseToken;

  @override
  void onInit() {
    // Fenix may construct a fresh controller; ensure a live TEC every time.
    msisdnController = TextEditingController(text: msisdn.value);
    getFirebaseToken();
    _loadPinStatus();
    super.onInit();
  }

  @override
  void onClose() {
    // Intentionally not disposing [msisdnController] here. See field note.
    super.onClose();
  }

  Future<void> _loadPinStatus() async {
    hasPinEnabled.value = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    isPinStatusLoading.value = false;
  }

  /// Passwordless login: validate phone → pick channel → request OTP → OTP screen.
  Future<void> continueWithOtp() async {
    // [authFormKey] is recreated when fenix rebuilds this controller, so the
    // mounted Form can still be holding the previous key and `currentState`
    // is legitimately null — the same hazard the field notes above describe
    // for [msisdnController]. A `!` here turned that into a crash inside the
    // tap handler.
    //
    // Validating through the Form is still preferred, because that is what
    // paints the inline error under the field. When it is unavailable, apply
    // the identical rule to the raw text so a bad number is still refused
    // rather than sent, and report it where the user can see it.
    final typed = msisdnController.text.trim();
    final formState = authFormKey.currentState;
    if (formState != null) {
      if (!formState.validate()) return;
    } else {
      final problem = validator(typed);
      if (problem != null) {
        errorText.value = problem;
        return;
      }
    }
    // Nothing else clears this, so a message set on the fallback path above
    // would otherwise outlive the number that caused it.
    errorText.value = null;

    msisdn(typed);
    final phone = msisdn.value;

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
      Get.offAllNamed(await SalesAgentSession.homeRoute(_preferenceManager));
      Get.snackbar(
        _t('Offline', 'Nje ya mtandao'),
        _t(
          'You\'re offline. Using your last session.',
          'Huna mtandao. Tunatumia kipindi chako cha mwisho.',
        ),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    var emailAvailable = false;
    try {
      final options = await _repository.requestLoginOtp(
        LoginOtpRequest(msisdn: phone, channel: 'OPTIONS'),
      );
      final data = options.data;
      if (data is Map) {
        emailAvailable = data['hasEmail'] == true;
      }
    } catch (_) {
      emailAvailable = false;
    }

    final ctx = Get.context;
    if (ctx == null) return;
    final channel = await showOtpChannelSheet(
      ctx,
      isSw: Get.locale?.languageCode == 'sw',
      emailAvailable: emailAvailable,
      phone: phone,
    );
    if (channel == null) return;

    await getFirebaseToken();
    isLoading(true);
    try {
      final res = await _repository
          .requestLoginOtp(
            LoginOtpRequest(msisdn: phone, channel: channel),
          )
          .timeout(const Duration(seconds: 25));
      if (res.responseCode != '0' && res.responseCode != null) {
        if (isMissingAccountError(res.message) ||
            isRemovedStaffError(res.message) ||
            await RemovedStaffPhones.contains(phone)) {
          await _clearLeftoverDeletedSession();
        }
        showErrorMessage(await _loginFailureCopy(res.message, phone));
        return;
      }
      await RemovedStaffPhones.forget(phone);
      await _preferenceManager.setString(
        PreferenceManager.keyUsername,
        phone,
      );
      Get.toNamed(
        Routes.OTP,
        arguments: {
          'msisdn': phone,
          'flow': 'login',
          'channel': channel,
        },
      );
    } on NotFoundException catch (e) {
      await _clearLeftoverDeletedSession();
      showErrorMessage(await _loginFailureCopy(e.message, phone, notFound: true));
    } on BaseException catch (e) {
      if (isMissingAccountError(e.message) ||
          isRemovedStaffError(e.message) ||
          await RemovedStaffPhones.contains(phone)) {
        await _clearLeftoverDeletedSession();
      }
      showErrorMessage(await _loginFailureCopy(e.message, phone));
    } on TimeoutException {
      showErrorMessage(await _loginFailureCopy(null, phone));
    } catch (_) {
      showErrorMessage(await _loginFailureCopy(null, phone));
    } finally {
      isLoading(false);
    }
  }

  Future<void> _clearLeftoverDeletedSession() async {
    if (Get.isRegistered<SessionService>()) {
      await Get.find<SessionService>().clearFullSession();
    } else {
      await _preferenceManager.clearSession();
    }
    await _preferenceManager.setBool(PreferenceManager.keyPinEnabled, false);
    await _preferenceManager.setString(PreferenceManager.keyPinCode, '');
    await _preferenceManager.setBool(PreferenceManager.keyFaceIdEnabled, false);
    await _preferenceManager.setBool(PreferenceManager.keyFirstLogin, true);
    hasPinEnabled.value = false;
  }

  Future<String> _loginFailureCopy(
    String? raw,
    String phone, {
    bool notFound = false,
  }) async {
    final removed = isRemovedStaffError(raw) ||
        await RemovedStaffPhones.contains(phone);
    if (removed) return removedStaffLoginMessage();
    if (notFound || isMissingAccountError(raw)) return missingAccountLoginMessage();
    if (raw != null && raw.trim().isNotEmpty) {
      return _loginAccessMessage(raw);
    }
    return _t('Could not send OTP', 'Imeshindikana kutuma OTP');
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(
      PreferenceManager.keyFirebaseToken,
    );
  }

  Future<void> clearPrefs() async {
    await _preferenceManager.setBool('seen_onboarding', false);
    await _preferenceManager.clear();
  }

  Future<void> proceedToLogin(LoginResponse res) async {
    _loginResponse(res);
    if (res.message == 'expired_version') {
      showErrorMessage(appLocalization.expiredVersion);
    } else if (res.message == 'auth_success' ||
        res.message == 'verify_code' ||
        (res.token != null && res.token!.isNotEmpty)) {
      await Get.find<SessionService>().saveFromLogin(res);
      await _syncAccountLanguage();
      await _preferenceManager.setString(
        PreferenceManager.keyUsername,
        loginResponse.user?.msisdn ?? msisdn.value,
      );
      await _preferenceManager.setString(
        PreferenceManager.keyFullName,
        loginResponse.user?.fullName ?? '',
      );

      if (res.message == 'auth_success' ||
          (res.token != null && res.token!.isNotEmpty)) {
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

        // A missing local PIN on an account that has one on the server is an
        // authentication step, not setup: this device has to prove it knows
        // the PIN already chosen elsewhere, so that gate stays. Creating a
        // first PIN does not, and is deferred to the launch router.
        final needsRemotePinConfirmation =
            !hasValidPin && await _hasRemotePinSet();

        if (needsRemotePinConfirmation) {
          triggerRemoteAccountSync();
          Get.offAllNamed(
            Routes.CHANGE_PIN,
            arguments: {
              WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
              'confirm_remote_pin': true,
            },
          );
        } else {
          triggerRemoteAccountSync();
          Get.offAllNamed(
            await SalesAgentSession.homeRoute(_preferenceManager),
            arguments: {
              'from_password_login': true, // unlocks Welcome Back "Continue" UX
              'from_otp_login': true,
              WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
            },
          );
        }
      } else {
        showErrorMessage(appLocalization.loginFailed);
      }
    } else {
      showErrorMessage(appLocalization.loginFailed);
    }
  }

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

  Future<void> _syncAccountLanguage() async {
    if (!Get.isRegistered<AppLocaleController>()) return;
    try {
      await Get.find<AppLocaleController>().syncWithAccount();
    } catch (_) {}
  }

  String? validator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return appLocalization.requiredField;
    }
    final phonePattern = RegExp(r'^0[678]\d{8}$');
    if (!phonePattern.hasMatch(phone)) {
      return _t(
        'Please enter a valid phone number (e.g., 0612345678)',
        'Tafadhali weka namba sahihi ya simu (mf. 0612345678)',
      );
    }
    return null;
  }
}
