import 'package:get/get.dart';

import '../controllers/rent_maintenance_cost_analysis_controller.dart';

class RentMaintenanceCostAnalysisBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentMaintenanceCostAnalysisController>(
        () => RentMaintenanceCostAnalysisController(),
      );
}
