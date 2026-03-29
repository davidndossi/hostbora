import 'package:get/get.dart';

import '../controllers/rent_define_tenant_charges_controller.dart';

class RentDefineTenantChargesBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentDefineTenantChargesController>(
        () => RentDefineTenantChargesController(),
      );
}
