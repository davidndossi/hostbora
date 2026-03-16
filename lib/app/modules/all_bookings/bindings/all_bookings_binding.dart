import 'package:get/get.dart';

import '../controllers/all_bookings_controller.dart';

class AllBookingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllBookingsController>(() => AllBookingsController());
  }
}
