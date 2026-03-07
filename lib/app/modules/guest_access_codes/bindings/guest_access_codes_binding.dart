import 'package:get/get.dart';

import '../controllers/guest_access_codes_controller.dart';

class GuestAccessCodesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuestAccessCodesController>(GuestAccessCodesController.new);
  }
}
