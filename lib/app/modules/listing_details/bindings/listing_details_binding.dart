import 'package:get/get.dart';

import '../controllers/listing_details_controller.dart';

class ListingDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListingDetailsController>(ListingDetailsController.new);
  }
}
