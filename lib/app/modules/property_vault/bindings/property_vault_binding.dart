import 'package:get/get.dart';

import '../controllers/property_vault_controller.dart';

class PropertyVaultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyVaultController>(PropertyVaultController.new);
  }
}
