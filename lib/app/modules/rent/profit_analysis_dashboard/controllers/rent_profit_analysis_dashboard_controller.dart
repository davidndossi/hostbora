import '../../../../core/base/base_controller.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentProfitAnalysisDashboardController extends BaseController
    with RentRealDataControllerMixin {
  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }

  void onApplyStrategy() {
    showSuccessMessage('Strategy applied');
  }

  void onOpenMenu() {}

  void onOpenProfile() {}
}
