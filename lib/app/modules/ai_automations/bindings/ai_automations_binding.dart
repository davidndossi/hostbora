import 'package:get/get.dart';

import '../controllers/ai_automations_controller.dart';

class AiAutomationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiAutomationsController>(AiAutomationsController.new);
  }
}
