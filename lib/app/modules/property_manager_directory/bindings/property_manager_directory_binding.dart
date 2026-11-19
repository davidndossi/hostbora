import 'package:get/get.dart';

import '../controllers/property_manager_directory_controller.dart';

class PropertyManagerDirectoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyManagerDirectoryController>(
      () => PropertyManagerDirectoryController(),
    );
  }
}
