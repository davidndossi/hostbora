import 'package:get/get.dart';

import '../controllers/rent_expected_payment_schedule_controller.dart';

class RentExpectedPaymentScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentExpectedPaymentScheduleController>(
      () => RentExpectedPaymentScheduleController(),
    );
  }
}
