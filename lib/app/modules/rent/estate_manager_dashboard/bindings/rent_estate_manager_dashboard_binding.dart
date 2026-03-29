import 'package:get/get.dart';

import '../controllers/rent_estate_manager_dashboard_controller.dart';

class RentEstateManagerDashboardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentEstateManagerDashboardController>(
        () => RentEstateManagerDashboardController(),
      );
}
