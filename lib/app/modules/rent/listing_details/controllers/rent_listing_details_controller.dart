import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentListingDetailsController extends BaseController
    with RentRealDataControllerMixin {
  final selectedBottomNavIndex = 1.obs;

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }

  void onBottomNavTap(int index) => selectedBottomNavIndex.value = index;

  void onEditListing() {}

  void onManageModules() {}

  void onAddNewUnit() {}

  void onViewAllLog() {}

  void onManageStaff() {}

  void onQuickAction(int index) {}

  void onUnitPrimaryAction() {
    Get.toNamed(Routes.RENT_HOST_DASHBOARD_PAYMENT_ALERTS);
  }

  void onReadUnitNote() {}
}
