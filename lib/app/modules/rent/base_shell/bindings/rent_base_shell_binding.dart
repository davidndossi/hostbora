import 'package:get/get.dart';

import '../../../settings/controllers/settings_controller.dart';
import '../../hub/controllers/rent_hub_controller.dart';
import '../../my_properties_hub/controllers/rent_my_properties_hub_controller.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../controllers/rent_base_shell_controller.dart';
import '../controllers/rent_others_tab_controller.dart';

/// Registers shell + all tab controllers so [IndexedStack] children resolve via GetView.
class RentBaseShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentBaseShellController>(() => RentBaseShellController());
    Get.lazyPut<RentHubController>(() => RentHubController());
    Get.lazyPut<RentMyPropertiesHubController>(() => RentMyPropertiesHubController());
    Get.lazyPut<RentTenantResidencyPaymentTrackerController>(() => RentTenantResidencyPaymentTrackerController());
    Get.lazyPut<RentOthersTabController>(() => RentOthersTabController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
