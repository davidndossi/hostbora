import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '/app/core/base/base_controller.dart';

enum PINStatus { verifyCurrent, enterFirst, enterSecond, equals, unequals }

class ChangePinController extends BaseController {
  final pinStatus = PINStatus.enterFirst.obs;
  final firstPIN = ''.obs;
  final secondPIN = ''.obs;
  final changePinMode = false.obs;

  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  AppRepository? _repository;

  String _storedPin = '';

  @override
  void onInit() {
    super.onInit();
    try {
      _repository =
          Get.find<AppRepository>(tag: (AppRepository).toString());
    } catch (_) {}
    final args = Get.arguments;
    if (args is Map && args['change_pin'] == true) {
      changePinMode.value = true;
      pinStatus(PINStatus.verifyCurrent);
      _loadStoredPin();
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

  int getCountsOfPIN() {
    if (pinStatus.value == PINStatus.verifyCurrent) {
      return firstPIN.value.length;
    }
    return firstPIN.value.length < 4
        ? firstPIN.value.length
        : secondPIN.value.length;
  }

  void setPIN(int pinNum) {
    if (pinStatus.value == PINStatus.verifyCurrent) {
      if (firstPIN.value.length < 4) {
        firstPIN('${firstPIN.value}$pinNum');
        if (firstPIN.value.length == 4) {
          _verifyCurrentPin();
        }
      }
      update();
      return;
    }

    if (firstPIN.value.length < 4) {
      final currentPIN = '${firstPIN.value}$pinNum';
      firstPIN(currentPIN);
      if (currentPIN.length < 4) {
        pinStatus(PINStatus.enterFirst);
      } else {
        pinStatus(PINStatus.enterSecond);
      }
    } else {
      final currentPIN = '${secondPIN.value}$pinNum';
      secondPIN(currentPIN);
      if (currentPIN.length < 4) {
        pinStatus(PINStatus.enterSecond);
      } else if (secondPIN.value == firstPIN.value) {
        pinStatus(PINStatus.equals);
      } else {
        pinStatus(PINStatus.unequals);
      }
    }
    update();
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

  void erase() {
    if (pinStatus.value == PINStatus.verifyCurrent) {
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
