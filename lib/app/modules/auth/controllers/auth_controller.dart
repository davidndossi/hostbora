import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/util.dart';
import '../../../core/widget/otp_channel_sheet.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/service/app_review_service.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_otp_request.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';

class AuthController extends BaseController {
  final msisdn = ''.obs;
  final errorText = Rxn<String>();
  final isLoading = false.obs;
  final hasPinEnabled = false.obs;
  final isPinStatusLoading = true.obs;
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;
  final authFormKey = GlobalKey<FormState>();

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
    if (!authFormKey.currentState!.validate()) return;

    msisdn(msisdnController.text.trim());
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
      await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace();
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

    final ctx = Get.context;
    if (ctx == null) return;

    final channel = await showOtpChannelSheet(
      ctx,
      isSw: Get.locale?.languageCode == 'sw',
      emailAvailable: true,
    );
    if (channel == null) return;

    await getFirebaseToken();
    callDataService<GeneralResponse>(
      _repository.requestLoginOtp(
        LoginOtpRequest(msisdn: phone, channel: channel),
      ),
      onStart: () => isLoading(true),
      onComplete: () => isLoading(false),
      onError: (e) {
        if (e is ApiException && e.message.isNotEmpty) {
          showErrorMessage(e.message);
        } else {
          showErrorMessage(_t('Could not send OTP', 'Imeshindikana kutuma OTP'));
        }
      },
      onSuccess: (res) async {
        if (res.responseCode != '0' && res.responseCode != null) {
          showErrorMessage(
            res.message ?? _t('Could not send OTP', 'Imeshindikana kutuma OTP'),
          );
          return;
        }
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
      },
    );
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

        if (!hasValidPin) {
          triggerRemoteAccountSync();
          final hasRemotePin = await _hasRemotePinSet();
          Get.offAllNamed(
            Routes.CHANGE_PIN,
            arguments: {
              WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true,
              if (hasRemotePin) 'confirm_remote_pin': true,
            },
          );
        } else {
          triggerRemoteAccountSync();
          await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace(
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
