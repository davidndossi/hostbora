import 'package:get/get.dart';

import '../controllers/rent_add_tenant_form_controller.dart';

class RentAddTenantFormBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentAddTenantFormController>(
        () => RentAddTenantFormController(),
      );
}
