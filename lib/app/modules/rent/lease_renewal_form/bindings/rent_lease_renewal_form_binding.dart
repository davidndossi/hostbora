import 'package:get/get.dart';

import '../controllers/rent_lease_renewal_form_controller.dart';

class RentLeaseRenewalFormBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentLeaseRenewalFormController>(
        () => RentLeaseRenewalFormController(),
      );
}
