import 'package:get/get.dart';

import '../controllers/failed_controller.dart';

class FailedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FailedController>(() => FailedController(), fenix: true);
  }
}
