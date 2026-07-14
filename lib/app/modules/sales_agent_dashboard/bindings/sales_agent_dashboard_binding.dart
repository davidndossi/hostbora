import 'package:get/get.dart';

import '../controllers/sales_agent_dashboard_controller.dart';

class SalesAgentDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesAgentDashboardController>(() => SalesAgentDashboardController());
  }
}
