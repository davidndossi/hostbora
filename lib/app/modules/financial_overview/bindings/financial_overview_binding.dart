import 'package:get/get.dart';

import '../controllers/financial_overview_controller.dart';

class FinancialOverviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinancialOverviewController>(FinancialOverviewController.new);
  }
}
