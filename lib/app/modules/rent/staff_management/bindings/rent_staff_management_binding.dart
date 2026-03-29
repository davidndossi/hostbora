import 'package:get/get.dart';

import '../controllers/rent_staff_management_controller.dart';

class RentStaffManagementBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentStaffManagementController>(
        () => RentStaffManagementController(),
      );
}
