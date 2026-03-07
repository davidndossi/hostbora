import 'package:get/get.dart';

import '../controllers/my_properties_controller.dart';

class MyPropertiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyPropertiesController>(MyPropertiesController.new);
  }
}
