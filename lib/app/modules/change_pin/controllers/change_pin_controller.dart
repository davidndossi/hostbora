import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

enum PINStatus { enterFirst, enterSecond, equals , unequals}

class ChangePinController extends BaseController {
  final pinStatus = PINStatus.enterFirst.obs;
  final firstPIN = ''.obs;
  final secondPIN = ''.obs;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager).toString());

  int getCountsOfPIN() {
    return firstPIN.value.length < 4 ? firstPIN.value.length : secondPIN.value.length;
  }

  void setPIN(int pinNum) {
    if (firstPIN.value.length < 4) {
      String currentPIN = "${firstPIN.value}$pinNum";
      firstPIN(currentPIN);
      if (currentPIN.length < 4) {
        pinStatus(PINStatus.enterFirst);
      } else {
        pinStatus(PINStatus.enterSecond);
      }
      } else {
        String currentPIN = "${secondPIN.value}$pinNum";
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

  void erase() {
    if (firstPIN.isEmpty) {
      pinStatus(PINStatus.enterFirst);
    } else if (firstPIN.value.length < 4) {
      String currentPIN = firstPIN.substring(0, firstPIN.value.length - 1);
      firstPIN(currentPIN);
      pinStatus(PINStatus.enterFirst);
    } else if (secondPIN.isEmpty) {
      pinStatus(PINStatus.enterSecond);
    } else {
      String currentPIN = secondPIN.substring(0, secondPIN.value.length - 1);
      secondPIN(currentPIN);
      pinStatus(PINStatus.enterSecond);
    }
    update();
  }

  void reset() {
    pinStatus(PINStatus.enterFirst);
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
              onPressed: () {
                Get.back(closeOverlays: true);
                Get.offAllNamed(Routes.MAIN);
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
    await _preferenceManager.setString(PreferenceManager.keyPinCode, newPin);
    await _preferenceManager.setBool(PreferenceManager.keyPinEnabled, true);
    await _preferenceManager.setBool(PreferenceManager.keyFirstLogin, false);
    await _preferenceManager.setInt(PreferenceManager.keyPinFailedAttempts, 0);
    await _preferenceManager.setInt(PreferenceManager.keyPinLockedUntilMs, 0);

    // Future: sync with backend via AppRepository + ChangePinRequest when available.
  }

  Future<bool> isPinOrBiometricSet() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    return canAuthenticate;
  }

}
