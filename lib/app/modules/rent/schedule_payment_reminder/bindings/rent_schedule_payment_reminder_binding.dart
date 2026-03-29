import 'package:get/get.dart';

import '../controllers/rent_schedule_payment_reminder_controller.dart';

class RentSchedulePaymentReminderBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentSchedulePaymentReminderController>(
        () => RentSchedulePaymentReminderController(),
      );
}
