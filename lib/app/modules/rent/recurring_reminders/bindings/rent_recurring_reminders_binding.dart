import 'package:get/get.dart';

import '../controllers/rent_recurring_reminders_controller.dart';

class RentRecurringRemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentRecurringRemindersController>(
      () => RentRecurringRemindersController(),
    );
  }
}
