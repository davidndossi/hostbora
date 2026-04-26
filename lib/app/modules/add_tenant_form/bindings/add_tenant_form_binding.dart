import 'package:get/get.dart';

import '../controllers/add_tenant_form_controller.dart';

class AddTenantFormBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<AddTenantFormController>(
    () => AddTenantFormController(),
  );
}
