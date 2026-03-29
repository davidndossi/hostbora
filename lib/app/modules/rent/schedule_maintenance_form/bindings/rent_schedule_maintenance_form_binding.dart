import 'package:get/get.dart';

import '../controllers/rent_schedule_maintenance_form_controller.dart';

class RentScheduleMaintenanceFormBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentScheduleMaintenanceFormController>(
        () => RentScheduleMaintenanceFormController(),
      );
}
