import 'package:get/get.dart';

import '../controllers/ai_manager_controller.dart';

class AiManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiManagerController>(AiManagerController.new);
  }
}
