import 'package:get/get.dart';

import '../controllers/unit_occupancy_controller.dart';

class UnitOccupancyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UnitOccupancyController>(UnitOccupancyController.new);
  }
}
