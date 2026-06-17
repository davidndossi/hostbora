import 'package:get/get.dart';

import '../controllers/inventory_item_form_controller.dart';

class InventoryItemFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryItemFormController>(() => InventoryItemFormController());
  }
}
