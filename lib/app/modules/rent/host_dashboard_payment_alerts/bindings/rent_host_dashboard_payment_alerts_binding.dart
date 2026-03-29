import 'package:get/get.dart';

import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

class RentHostDashboardPaymentAlertsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentHostDashboardPaymentAlertsController>(
        () => RentHostDashboardPaymentAlertsController(),
      );
}
