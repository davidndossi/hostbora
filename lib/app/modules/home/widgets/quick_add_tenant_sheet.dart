import 'package:get/get.dart';

import '../../add_tenant_form/controllers/add_tenant_form_controller.dart';
import '../../add_tenant_form/views/add_tenant_form_view.dart';
import 'quick_wizard_shell.dart';

/// Same bottom sheet used when Add Tenant is chosen from the home quick actions.
Future<bool?> showQuickAddTenantSheet() async {
  if (Get.isRegistered<AddTenantFormController>()) {
    await Get.delete<AddTenantFormController>(force: true);
  }
  Get.put(AddTenantFormController());
  try {
    return await showQuickWizardSheet<bool>(
      title: 'Add Tenant',
      builder: (_) => AddTenantFormView(),
    );
  } finally {
    if (Get.isRegistered<AddTenantFormController>()) {
      await Get.delete<AddTenantFormController>(force: true);
    }
  }
}
