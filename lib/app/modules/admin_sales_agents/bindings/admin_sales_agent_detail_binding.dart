import 'package:get/get.dart';

import '../controllers/admin_sales_agent_detail_controller.dart';

class AdminSalesAgentDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminSalesAgentDetailController>(() => AdminSalesAgentDetailController());
  }
}
