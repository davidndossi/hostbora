import 'package:get/get.dart';

import '../../hub/controllers/rent_hub_controller.dart';
import '../../my_properties_hub/controllers/rent_my_properties_hub_controller.dart';
import '../../staff_management/controllers/rent_staff_management_controller.dart';
import '../controllers/rent_base_shell_controller.dart';
import '../controllers/rent_others_tab_controller.dart';

/// Registers shell + all tab controllers so [IndexedStack] children resolve via GetView.
class RentBaseShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentBaseShellController>(() => RentBaseShellController());
    Get.lazyPut<RentHubController>(() => RentHubController());
    Get.lazyPut<RentMyPropertiesHubController>(RentMyPropertiesHubController.new);
    Get.lazyPut<RentStaffManagementController>(() => RentStaffManagementController());
    Get.lazyPut<RentOthersTabController>(() => RentOthersTabController());
  }
}
