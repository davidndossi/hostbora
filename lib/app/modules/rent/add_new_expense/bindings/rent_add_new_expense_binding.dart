import 'package:get/get.dart';

import '../controllers/rent_add_new_expense_controller.dart';

class RentAddNewExpenseBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentAddNewExpenseController>(
        () => RentAddNewExpenseController(),
      );
}
