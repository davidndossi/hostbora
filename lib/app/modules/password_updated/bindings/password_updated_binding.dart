import 'package:get/get.dart';

import '../controllers/password_updated_controller.dart';

class PasswordUpdatedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PasswordUpdatedController>(
      () => PasswordUpdatedController(),
      fenix: true,
    );
  }
}
