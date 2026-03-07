import 'package:get/get.dart';

import '../controllers/team_and_staff_controller.dart';

class TeamAndStaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamAndStaffController>(TeamAndStaffController.new);
  }
}
