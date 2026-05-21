import 'package:get/get.dart';

import '../../../data/local/design_moodboards_store.dart';
import '../controllers/design_moodboard_controller.dart';

class DesignMoodboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DesignMoodboardsStore>()) {
      Get.lazyPut<DesignMoodboardsStore>(DesignMoodboardsStore.new, fenix: true);
    }
    Get.lazyPut<DesignMoodboardController>(
      () => DesignMoodboardController(store: Get.find<DesignMoodboardsStore>()),
    );
  }
}
