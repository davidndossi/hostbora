import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class WelcomeBackController extends BaseController {
  final pinLength = 4;
  final enteredPin = ''.obs;

  /// True when user just logged in with phone+password; show Continue instead of PIN.
  final fromPasswordLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    fromPasswordLogin.value = args?['from_password_login'] == true;
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

  void authenticateWithBiometrics() async {
    // TODO: integrate local_auth if available
    // For now just navigate to home after a short delay (simulate success)
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.MAIN, arguments: {'initialMenu': 'home'});
  }
}
