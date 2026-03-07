import 'package:get/get.dart';

import '../controllers/staff_detail_controller.dart';

class StaffDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffDetailController>(() => StaffDetailController());
  }
}
