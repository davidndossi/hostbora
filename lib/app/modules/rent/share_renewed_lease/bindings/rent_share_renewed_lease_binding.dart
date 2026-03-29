import 'package:get/get.dart';

import '../controllers/rent_share_renewed_lease_controller.dart';

class RentShareRenewedLeaseBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentShareRenewedLeaseController>(
        () => RentShareRenewedLeaseController(),
      );
}
