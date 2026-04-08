import 'package:get/get.dart';

import '../controllers/rent_host_calendar_controller.dart';


class HostCalendarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentHostCalendarController>(() => RentHostCalendarController());
  }
}
