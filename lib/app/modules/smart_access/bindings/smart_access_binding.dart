import 'package:get/get.dart';

import '../controllers/smart_access_controller.dart';

class SmartAccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SmartAccessController>(SmartAccessController.new);
  }
}
