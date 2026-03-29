import 'package:get/get.dart';

import '../controllers/rent_listing_details_controller.dart';

class RentListingDetailsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentListingDetailsController>(
        () => RentListingDetailsController(),
      );
}
