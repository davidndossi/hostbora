import 'package:get/get.dart';

import '../controllers/rent_listing_analytics_dashboard_controller.dart';

class RentListingAnalyticsDashboardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentListingAnalyticsDashboardController>(
        () => RentListingAnalyticsDashboardController(),
      );
}
