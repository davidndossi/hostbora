import 'package:get/get.dart';

import '../controllers/rent_staff_payroll_details_controller.dart';

class RentStaffPayrollDetailsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentStaffPayrollDetailsController>(
        () => RentStaffPayrollDetailsController(),
      );
}
