import 'package:get/get.dart';

import '../controllers/refine_scan_controller.dart';

class RefineScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RefineScanController>(RefineScanController.new);
  }
}
