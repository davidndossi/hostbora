import 'package:get/get.dart';

import '../controllers/rent_listing_activity_log_controller.dart';

class RentListingActivityLogBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentListingActivityLogController>(
      () => RentListingActivityLogController(),
    );
  }
}
