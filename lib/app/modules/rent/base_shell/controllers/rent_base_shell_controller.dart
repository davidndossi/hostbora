import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';

/// Drives bottom navigation for the rent shell (Dashboard, Listings, Staff, Others).
class RentBaseShellController extends BaseController {
  final currentTab = 0.obs;

  static const tabCount = 4;

  void setTab(int index) {
    if (index >= 0 && index < tabCount) {
      currentTab.value = index;
    }
  }
}
