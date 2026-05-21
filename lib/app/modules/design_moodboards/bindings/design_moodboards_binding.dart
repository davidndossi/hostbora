import 'package:get/get.dart';

import '../../../data/local/design_moodboards_store.dart';
import '../controllers/design_moodboards_controller.dart';

class DesignMoodboardsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DesignMoodboardsStore>(DesignMoodboardsStore.new, fenix: true);
    Get.lazyPut<DesignMoodboardsController>(
      () => DesignMoodboardsController(store: Get.find<DesignMoodboardsStore>()),
    );
  }
}
