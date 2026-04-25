import 'package:get/get.dart';

import '../controllers/rent_smart_utility_dashboard_controller.dart';

class RentSmartUtilityDashboardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentSmartUtilityDashboardController>(
        () => RentSmartUtilityDashboardController(),
  );
}