import 'package:get/get.dart';

import '../controllers/property_manager_profile_controller.dart';

class PropertyManagerProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyManagerProfileController>(
      () => PropertyManagerProfileController(),
    );
  }
}
