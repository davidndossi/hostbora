import 'package:get/get.dart';

import '../controllers/rent_add_income_form_controller.dart';

class RentAddIncomeFormBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentAddIncomeFormController>(
        () => RentAddIncomeFormController(),
      );
}
