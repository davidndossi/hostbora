import 'package:get/get.dart';

import '../controllers/inventory_tracking_controller.dart';

class InventoryTrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryTrackingController>(() => InventoryTrackingController());
  }
}
