import 'package:get/get.dart';

import '../controllers/edit_listing_controller.dart';

class EditListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditListingController>(EditListingController.new);
  }
}
