import 'package:get/get.dart';

import '../controllers/rent_add_new_listing_controller.dart';

class RentAddNewListingBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentAddNewListingController>(
        () => RentAddNewListingController(),
      );
}
