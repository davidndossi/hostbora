import 'package:get/get.dart';

import '../controllers/monthly_income_reports_controller.dart';

class MonthlyIncomeReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MonthlyIncomeReportsController>(
      MonthlyIncomeReportsController.new,
    );
  }
}
