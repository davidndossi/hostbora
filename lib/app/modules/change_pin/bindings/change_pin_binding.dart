import 'package:get/get.dart';

import '../controllers/change_pin_controller.dart';

class ChangePinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePinController>(
      () => ChangePinController(),
    );
  }
}
