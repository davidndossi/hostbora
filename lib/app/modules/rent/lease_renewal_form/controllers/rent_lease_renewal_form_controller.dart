import '../../../../core/base/base_controller.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentLeaseRenewalFormController extends BaseController
    with RentRealDataControllerMixin {
  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }
}
