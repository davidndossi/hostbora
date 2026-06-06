import 'package:get/get.dart';

import '../../rent/staff_management/controllers/rent_staff_management_controller.dart';
import '../../rent/staff_payroll_details/controllers/rent_staff_payroll_details_controller.dart';
import '../controllers/listing_details_controller.dart';

class ListingDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListingDetailsController>(ListingDetailsController.new);
    Get.lazyPut<RentStaffManagementController>(
      RentStaffManagementController.new,
      fenix: true,
    );
    Get.lazyPut<RentStaffPayrollDetailsController>(
      RentStaffPayrollDetailsController.new,
      fenix: true,
    );
  }
}
