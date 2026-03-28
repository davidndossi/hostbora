import 'package:get/get.dart';

import '../controllers/design_moodboard_controller.dart';

class DesignMoodboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DesignMoodboardController>(DesignMoodboardController.new);
  }
}
