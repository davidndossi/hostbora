import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Keep factory so returning to Auth after OTP / Create Account works.
    // Do not dispose TextEditingControllers in AuthController.onClose while
    // AuthView can remain mounted under a pushed route.
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    }
  }
}
