import 'package:get/get.dart';

import '../controllers/edit_unit_controller.dart';

class EditUnitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditUnitController>(EditUnitController.new);
  }
}
