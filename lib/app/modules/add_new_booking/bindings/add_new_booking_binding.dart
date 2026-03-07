import 'package:get/get.dart';

import '../controllers/add_new_booking_controller.dart';

class AddNewBookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddNewBookingController>(AddNewBookingController.new);
  }
}
