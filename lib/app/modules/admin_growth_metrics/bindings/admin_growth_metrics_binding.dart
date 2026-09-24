import 'package:get/get.dart';

import '../controllers/admin_growth_metrics_controller.dart';

class AdminGrowthMetricsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminGrowthMetricsController>(
      () => AdminGrowthMetricsController(),
    );
  }
}
