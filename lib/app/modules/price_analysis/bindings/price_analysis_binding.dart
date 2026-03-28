import 'package:get/get.dart';

import '../controllers/price_analysis_controller.dart';

class PriceAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PriceAnalysisController>(PriceAnalysisController.new);
  }
}
