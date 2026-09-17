import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

enum PINStatus { verifyCurrent, confirmRemote, enterFirst, enterSecond, equals, unequals }

class ChangePinController extends BaseController {
  final pinStatus = PINStatus.enterFirst.obs;
  final firstPIN = ''.obs;
  final secondPIN = ''.obs;
  final changePinMode = false.obs;

  /// True when confirming an existing PIN already saved on the backend
  /// (returning user, new device) instead of creating a brand-new one.
  final remoteConfirmMode = false.obs;
  final isVerifyingRemotePin = false.obs;
  final remoteConfirmError = Rxn<String>();

  /// True once the user taps "Forgot PIN? Set a new one" from remote-confirm
  /// mode. The subsequent save is allowed to bypass the old-PIN check since a
  /// fresh password sign-in already proved identity.
  bool _viaPasswordReauth = false;

  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  AppRepository? _repository;

  String _storedPin = '';
  Map? _redirectArgs;

  @override
  void onInit() {
    super.onInit();
    try {
      _repository =
          Get.find<AppRepository>(tag: (AppRepository).toString());
    } catch (_) {}
    final args = Get.arguments;
    if (args is Map) {
      _redirectArgs = args;
      if (args['change_pin'] == true) {
        changePinMode.value = true;
        pinStatus(PINStatus.verifyCurrent);
        _loadStoredPin();
      } else if (args['confirm_remote_pin'] == true) {
        remoteConfirmMode.value = true;
        pinStatus(PINStatus.confirmRemote);
      }
    }
  }

  Future<void> _loadStoredPin() async {
    _storedPin = await _preferenceManager.getString(
      PreferenceManager.keyPinCode,
      defaultValue: '',
    );
    if (_storedPin.isEmpty) {
      showErrorMessage(
        _t('PIN is not set yet.', 'PIN bado haijawekwa.'),
      );
      Get.back();
    }
  }

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  /// Returns to the previous screen, or Auth when this page is the stack root
  /// (e.g. post-login PIN setup via [Get.offAllNamed]).
  void goBack() {
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
      return;
    }
    Get.offAllNamed(Routes.AUTH);
  }

  /// Brief pause after the 4th digit so all four indicators paint before
  /// verify / advance clears or switches the active PIN field.
  static const _pinFeedbackDelay = Duration(milliseconds: 220);

  int getCountsOfPIN() {
    switch (pinStatus.value) {
      case PINStatus.verifyCurrent:
      case PINStatus.confirmRemote:
      case PINStatus.enterFirst:
        return firstPIN.value.length;
      case PINStatus.enterSecond:
      case PINStatus.equals:
      case PINStatus.unequals:
        return secondPIN.value.length;
    }
  }

  Future<void> setPIN(int pinNum) async {
    if (pinStatus.value == PINStatus.confirmRemote) {
      if (isVerifyingRemotePin.value) return;
      if (firstPIN.value.length >= 4) return;
      remoteConfirmError.value = null;
      firstPIN('${firstPIN.value}$pinNum');
      update();
      if (firstPIN.value.length == 4) {
        await Future.delayed(_pinFeedbackDelay);
        if (firstPIN.value.length != 4 ||
            pinStatus.value != PINStatus.confirmRemote) {
          return;
        }
        await _verifyRemotePin();
      }
      return;
    }

    if (pinStatus.value == PINStatus.verifyCurrent) {
      if (firstPIN.value.length >= 4) return;
      firstPIN('${firstPIN.value}$pinNum');
      update();
      if (firstPIN.value.length == 4) {
        await Future.delayed(_pinFeedbackDelay);
        if (firstPIN.value.length != 4 ||
            pinStatus.value != PINStatus.verifyCurrent) {
          return;
        }
        _verifyCurrentPin();
      }
      return;
    }

    if (firstPIN.value.length < 4) {
      final currentPIN = '${firstPIN.value}$pinNum';
      firstPIN(currentPIN);
      pinStatus(PINStatus.enterFirst);
      update();
      if (currentPIN.length == 4) {
        await Future.delayed(_pinFeedbackDelay);
        if (firstPIN.value.length != 4 ||
            pinStatus.value != PINStatus.enterFirst) {
          return;
        }
        pinStatus(PINStatus.enterSecond);
        update();
      }
      return;
    }

    if (secondPIN.value.length >= 4) return;
    final currentPIN = '${secondPIN.value}$pinNum';
    secondPIN(currentPIN);
    pinStatus(PINStatus.enterSecond);
    update();
    if (currentPIN.length == 4) {
      await Future.delayed(_pinFeedbackDelay);
      if (secondPIN.value.length != 4 ||
          pinStatus.value != PINStatus.enterSecond) {
        return;
      }
      if (secondPIN.value == firstPIN.value) {
        pinStatus(PINStatus.equals);
      } else {
        pinStatus(PINStatus.unequals);
      }
      update();
    }
  }

  void _verifyCurrentPin() {
    if (firstPIN.value != _storedPin) {
      showErrorMessage(
        _t('Current PIN is incorrect', 'PIN ya sasa si sahihi'),
      );
      firstPIN('');
      pinStatus(PINStatus.verifyCurrent);
      update();
      return;
    }
    firstPIN('');
    secondPIN('');
    pinStatus(PINStatus.enterFirst);
    update();
  }

  Map<String, dynamic>? get _redirectWorkspaceArgs {
    final redirect = _redirectArgs?[
            WorkspaceContextService.rentHubRedirectListingsIfEmptyKey] ==
        true;
    return redirect
        ? {WorkspaceContextService.rentHubRedirectListingsIfEmptyKey: true}
        : null;
  }

  /// Verifies the entered PIN against the account's remote hash (new device,
  /// returning user). On success, the PIN is cached locally so future app-lock
  /// unlocks work offline too, and the user proceeds straight into the app.
  Future<void> _verifyRemotePin() async {
    final pin = firstPIN.value;
    isVerifyingRemotePin.value = true;
    try {
      final res = await _repository?.verifyPinOnServer(pin);
      final data = res?.data;
      final isValid = data is Map && data['valid'] == true;
      if (isValid) {
        await _preferenceManager.setString(PreferenceManager.keyPinCode, pin);
        await _preferenceManager.setBool(PreferenceManager.keyPinEnabled, true);
        await _preferenceManager.setBool(PreferenceManager.keyFirstLogin, false);
        await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
        await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);
        showSuccessMessage(_t('Welcome back!', 'Karibu tena!'));
        await Get.find<WorkspaceContextService>()
            .offAllToPreferredWorkspace(arguments: _redirectWorkspaceArgs);
        return;
      }

      final remaining = (data is Map ? data['remainingAttempts'] : null) as int?;
      remoteConfirmError.value = remaining != null
          ? _t(
              'Incorrect PIN. $remaining attempt(s) left.',
              'PIN si sahihi. Umebakiwa na jaribio $remaining.',
            )
          : _t('Incorrect PIN', 'PIN si sahihi');
      firstPIN('');
    } catch (e) {
      remoteConfirmError.value = e
          .toString()
          .replaceFirst('Exception: ', '');
      firstPIN('');
    } finally {
      isVerifyingRemotePin.value = false;
      update();
    }
  }

  /// Switches from "confirm your existing PIN" into first-time-setup mode so
  /// the user can create a brand-new PIN. Allowed to bypass the old-PIN check
  /// server-side since the user is already fully authenticated via password.
  void forgotRemotePin() {
    _viaPasswordReauth = true;
    remoteConfirmMode.value = false;
    remoteConfirmError.value = null;
    firstPIN('');
    secondPIN('');
    pinStatus(PINStatus.enterFirst);
  }

  void erase() {
    if (pinStatus.value == PINStatus.verifyCurrent ||
        pinStatus.value == PINStatus.confirmRemote) {
      if (firstPIN.value.isNotEmpty) {
        firstPIN(firstPIN.value.substring(0, firstPIN.value.length - 1));
      }
      update();
      return;
    }

    if (firstPIN.isEmpty) {
      pinStatus(PINStatus.enterFirst);
    } else if (firstPIN.value.length < 4) {
      final currentPIN = firstPIN.value.substring(0, firstPIN.value.length - 1);
      firstPIN(currentPIN);
      pinStatus(PINStatus.enterFirst);
    } else if (secondPIN.isEmpty) {
      pinStatus(PINStatus.enterSecond);
    } else {
      final currentPIN =
          secondPIN.value.substring(0, secondPIN.value.length - 1);
      secondPIN(currentPIN);
      pinStatus(PINStatus.enterSecond);
    }
    update();
  }

  void reset() {
    pinStatus(changePinMode.value ? PINStatus.verifyCurrent : PINStatus.enterFirst);
    firstPIN('');
    secondPIN('');
    Get.back(closeOverlays: true);
  }

  void _handleChangePinError(Exception e) {
    showErrorMessage(
      e.toString().replaceFirst('Exception: ', ''),
    );
  }

  void _handleChangePinSuccess(GeneralResponse res) async {
    showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(15))),
          icon: SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(
              'images/tick-circle.svg',
            ),
          ),
          title: const Text('Your PIN code changed successfully!'),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () async {
                Get.back(closeOverlays: true);
                final args = Get.arguments;
                final redirect = args is Map &&
                    args[WorkspaceContextService.rentHubRedirectListingsIfEmptyKey] ==
                        true;
                await Get.find<WorkspaceContextService>().offAllToPreferredWorkspace(
                  arguments: redirect
                      ? {
                          WorkspaceContextService.rentHubRedirectListingsIfEmptyKey:
                              true,
                        }
                      : null,
                );
              },
              child: const Text('OK'),
            )
          ],
        ));
  }

  /// Persists the new PIN locally and shows success. Backend sync can be wired
  /// when `AppRepository` exposes a change-PIN endpoint.
  Future<void> changePin() async {
    final newPin = firstPIN.value;
    final confirm = secondPIN.value;
    if (newPin.length != 4 || confirm.length != 4 || newPin != confirm) {
      pinStatus(PINStatus.unequals);
      return;
    }

    await callDataServiceSilent<void>(
      _persistNewPin(newPin),
      onSuccess: (_) {
        _handleChangePinSuccess(
          GeneralResponse(responseCode: '0', message: 'ok'),
        );
      },
      onError: _handleChangePinError,
    );
  }

  Future<void> _persistNewPin(String newPin) async {
    final oldPin = _storedPin;
    await _preferenceManager.setString(PreferenceManager.keyPinCode, newPin);
    await _preferenceManager.setBool(PreferenceManager.keyPinEnabled, true);
    await _preferenceManager.setBool(PreferenceManager.keyFirstLogin, false);
    await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
    await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);

    // Best-effort sync with backend — failure is logged only, never blocks UI.
    try {
      await _repository?.changePinOnServer({
        'currentPin': oldPin,
        'newPin': newPin,
        'viaPasswordReauth': _viaPasswordReauth,
      });
    } catch (e) {
      logger.w('changePinOnServer failed (non-blocking): $e');
    }
  }

  Future<bool> isPinOrBiometricSet() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    return canAuthenticate;
  }
}
