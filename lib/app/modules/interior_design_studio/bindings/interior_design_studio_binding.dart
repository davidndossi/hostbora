import 'package:get/get.dart';

import '../controllers/interior_design_studio_controller.dart';

class InteriorDesignStudioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InteriorDesignStudioController>(InteriorDesignStudioController.new);
  }
}
