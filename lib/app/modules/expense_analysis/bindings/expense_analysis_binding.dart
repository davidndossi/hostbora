import 'package:get/get.dart';

import '../controllers/expense_analysis_controller.dart';

class ExpenseAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseAnalysisController>(ExpenseAnalysisController.new);
  }
}
