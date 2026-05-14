import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/service/workspace_context_service.dart';

/// Drives bottom navigation for the rent shell (Dashboard, Listings, Tenants, More, Settings).
class RentBaseShellController extends BaseController {
  final currentTab = 0.obs;

  static const tabCount = 5;

  /// Bottom bar order matches [RentBaseShellView] `IndexedStack` children.
  static const int tabDashboard = 0;
  static const int tabListings = 1;
  static const int tabTenants = 2;
  static const int tabMore = 3;
  static const int tabSettings = 4;

  bool _pendingRedirectListingsIfHubEmpty = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map &&
        args[WorkspaceContextService.rentHubRedirectListingsIfEmptyKey] == true) {
      _pendingRedirectListingsIfHubEmpty = true;
    }
  }

  /// One-shot: true if we should consider switching to Listings when the hub loads empty.
  bool pullPendingRentHubListingsRedirect() {
    if (!_pendingRedirectListingsIfHubEmpty) return false;
    _pendingRedirectListingsIfHubEmpty = false;
    return true;
  }

  void setTab(int index) {
    if (index >= 0 && index < tabCount) {
      currentTab.value = index;
    }
  }
}
