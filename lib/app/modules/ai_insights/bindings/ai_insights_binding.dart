import 'package:get/get.dart';

import '../controllers/ai_insights_controller.dart';

class AiInsightsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiInsightsController>(AiInsightsController.new);
  }
}
