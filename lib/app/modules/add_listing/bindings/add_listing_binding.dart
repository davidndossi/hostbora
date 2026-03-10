import 'package:get/get.dart';

import '../../../data/service/nominatim_service.dart';
import '../controllers/add_listing_controller.dart';

class AddListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NominatimService>(NominatimService.new);
    Get.lazyPut<AddListingController>(AddListingController.new);
  }
}
