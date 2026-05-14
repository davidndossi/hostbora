import 'package:get/get.dart';

import '../controllers/rent_utility_usage_graph_controller.dart';

class RentUtilityUsageGraphBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<RentUtilityUsageGraphController>()) {
      Get.delete<RentUtilityUsageGraphController>(force: true);
    }
    Get.put(RentUtilityUsageGraphController());
  }
}
