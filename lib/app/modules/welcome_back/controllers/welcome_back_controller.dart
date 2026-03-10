import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class WelcomeBackController extends BaseController {
  final pinLength = 4;
  final enteredPin = ''.obs;

  /// True when user just logged in with phone+password; show Continue instead of PIN.
  final fromPasswordLogin = false.obs;

  /// True when device has biometrics available (fingerprint or face).
  final canUseBiometrics = false.obs;

  /// True while fingerprint/face auth is in progress.
  final isBiometricAuthInProgress = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    fromPasswordLogin.value = args?['from_password_login'] == true;
    _checkBiometricsAvailable();
  }

  Future<void> _checkBiometricsAvailable() async {
    try {
      final auth = LocalAuthentication();
      final available = await auth.getAvailableBiometrics();
      final supported = await auth.isDeviceSupported();
      canUseBiometrics.value = supported &&
          (available.contains(BiometricType.strong) ||
              available.contains(BiometricType.weak) ||
              available.contains(BiometricType.fingerprint) ||
              available.contains(BiometricType.face));
    } catch (_) {
      canUseBiometrics.value = false;
    }
  }

  void onKeyTap(String digit) {
    if (enteredPin.value.length >= pinLength) return;
    enteredPin.value = enteredPin.value + digit;
    if (enteredPin.value.length == pinLength) {
      _validateAndNavigate();
    }
  }

  void onBackspace() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(0, enteredPin.value.length - 1);
    }
  }

  void _validateAndNavigate() {
    // TODO: validate PIN against stored hash; for now accept any 4 digits → go to home
    Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
  }

  void close() => Get.back();

  void continueToApp() {
    Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
  }

  void help() => Get.toNamed(Routes.SUPPORT);

  void forgotPin() {
    // TODO: navigate to PIN reset / auth flow
    Get.offAllNamed(Routes.AUTH);
  }

  Future<void> authenticateWithBiometrics() async {
    if (!canUseBiometrics.value) {
      showErrorMessage('Biometrics not available. Use PIN to sign in.');
      return;
    }
    isBiometricAuthInProgress.value = true;
    try {
      final auth = LocalAuthentication();
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Sign in with fingerprint to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        showErrorMessage('Biometrics not available');
      } else if (e.code == auth_error.notEnrolled) {
        showErrorMessage('No fingerprint or face enrolled. Use PIN.');
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        showErrorMessage('Too many attempts. Use PIN or try again later.');
      } else if (e.code != auth_error.passcodeNotSet &&
          e.code != 'UserCanceled' &&
          e.code != 'Canceled') {
        showErrorMessage('Biometric sign in failed. Use PIN.');
      }
    } catch (e) {
      showErrorMessage('Biometric sign in failed. Use PIN.');
    } finally {
      isBiometricAuthInProgress.value = false;
    }
  }
}
