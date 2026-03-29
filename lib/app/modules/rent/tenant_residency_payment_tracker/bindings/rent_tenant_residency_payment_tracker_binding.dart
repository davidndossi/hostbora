import 'package:get/get.dart';

import '../controllers/rent_tenant_residency_payment_tracker_controller.dart';

class RentTenantResidencyPaymentTrackerBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentTenantResidencyPaymentTrackerController>(
        () => RentTenantResidencyPaymentTrackerController(),
      );
}
