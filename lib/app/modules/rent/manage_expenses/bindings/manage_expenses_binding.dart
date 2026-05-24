import 'package:get/get.dart';

import '../controllers/manage_expenses_controller.dart';

class ManageExpensesBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageExpensesController>(
      () => ManageExpensesController(),
      fenix: true,
    );
  }
}
