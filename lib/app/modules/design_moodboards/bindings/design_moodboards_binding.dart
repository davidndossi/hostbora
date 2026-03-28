import 'package:get/get.dart';

import '../controllers/design_moodboards_controller.dart';

class DesignMoodboardsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DesignMoodboardsController>(() => DesignMoodboardsController());
  }
}
