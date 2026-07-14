import 'package:get/get.dart';

import '../controllers/admin_sales_agents_controller.dart';

class AdminSalesAgentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminSalesAgentsController>(() => AdminSalesAgentsController());
  }
}
