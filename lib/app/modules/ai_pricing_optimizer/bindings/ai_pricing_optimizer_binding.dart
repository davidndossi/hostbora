import 'package:get/get.dart';

import '../controllers/ai_pricing_optimizer_controller.dart';

class AiPricingOptimizerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiPricingOptimizerController>(AiPricingOptimizerController.new);
  }
}
