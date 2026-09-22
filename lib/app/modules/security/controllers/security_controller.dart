import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class SecurityController extends BaseController {
  SecurityController()
      : _preferenceManager =
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString());

  final PreferenceManager _preferenceManager;
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final faceIdEnabled = false.obs;
  final pinEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSecurityPrefs();
  }

  Future<void> _loadSecurityPrefs() async {
    pinEnabled.value = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    faceIdEnabled.value = await _preferenceManager.getBool(
      PreferenceManager.keyFaceIdEnabled,
      defaultValue: false,
    );
  }

  void goBack() => Get.back();

  // void changePassword() => Get.toNamed(Routes.CHANGE_PASSWORD);

  Future<void> openPinCode() async {
    // Enabling PIN lock for the first time on this device: if the account
    // already has a PIN saved remotely (set on another device), let the user
    // confirm/reuse it instead of creating one that would fail to sync.
    var confirmRemotePin = false;
    if (!pinEnabled.value) {
      try {
        final res = await _repository.getPinStatus();
        confirmRemotePin = res.data is Map && res.data['hasPinSet'] == true;
      } catch (e) {
        logger.w('getPinStatus failed (non-blocking): $e');
      }
    }
    Get.toNamed(
      Routes.CHANGE_PIN,
      arguments: {
        'setup_pin': true,
        'change_pin': pinEnabled.value,
        if (confirmRemotePin) 'confirm_remote_pin': true,
      },
    )?.then((_) => _loadSecurityPrefs());
  }

  Future<void> toggleFaceId(bool enabled) async {
    if (enabled) {
      final pinCode = await _preferenceManager.getString(
        PreferenceManager.keyPinCode,
        defaultValue: '',
      );
      final pinOn = await _preferenceManager.getBool(
        PreferenceManager.keyPinEnabled,
        defaultValue: false,
      );
      if (!pinOn || pinCode.length != 4) {
        faceIdEnabled.value = false;
        showErrorMessage(appLocalization.faceIdRequiresPinMessage);
        return;
      }

      try {
        final auth = LocalAuthentication();
        final supported = await auth.isDeviceSupported();
        final available = await auth.getAvailableBiometrics();
        final canUse = supported &&
            (available.contains(BiometricType.strong) ||
                available.contains(BiometricType.weak) ||
                available.contains(BiometricType.fingerprint) ||
                available.contains(BiometricType.face));
        if (!canUse) {
          faceIdEnabled.value = false;
          showErrorMessage(appLocalization.faceIdNotAvailableMessage);
          return;
        }
      } catch (_) {
        faceIdEnabled.value = false;
        showErrorMessage(appLocalization.faceIdNotAvailableMessage);
        return;
      }
    }

    faceIdEnabled.value = enabled;
    await _preferenceManager.setBool(
      PreferenceManager.keyFaceIdEnabled,
      enabled,
    );
  }

  void openTwoFactor() {
    showErrorMessage(appLocalization.twoFactorNotConfiguredMessage);
  }

  void openPrivacyPolicy() => Get.toNamed(Routes.PRIVACY);

  Future<void> confirmDeleteAccount() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.deleteAccountConfirmTitle),
        content: Text(appLocalization.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(appLocalization.deleteAccountConfirmAction),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok != true) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    if (isBusy.value) return;
    await runBusy(() async {
      try {
        final res = await _repository.deleteMyAccount();
        if (!res.isSuccess) {
          showErrorMessage(
            res.message ?? appLocalization.deleteAccountFailed,
          );
          return;
        }
        await _preferenceManager.clearSession();
        Get.offAllNamed(AppPages.auth);
      } catch (e) {
        logger.e('deleteAccount failed: $e');
        showErrorMessage(appLocalization.deleteAccountFailed);
      }
    });
  }
}
