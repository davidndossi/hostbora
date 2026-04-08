import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_property_estimate_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentPropertyRoiAnalysisController extends BaseController
    with RentRealDataControllerMixin {
  RentPropertyRoiAnalysisController()
      : _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>();

  final RentPropertyEstimateLocalDataSource _estimateLocal;

  final selectedPropertyLabel = ''.obs;
  final selectedPropertyRef = ''.obs;
  final estimate = Rxn<RentPropertyEstimateRecord>();

  @override
  void onReady() {
    super.onReady();
    selectedPropertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    selectedPropertyLabel.value = (Get.parameters['propertyLabel'] ?? '').trim();
    loadAll();
  }

  Future<void> loadAll() async {
    await loadRealDataSnapshot();
    if (selectedPropertyRef.value.isNotEmpty) {
      estimate.value = await _estimateLocal.findByPropertyRef(selectedPropertyRef.value);
    } else {
      estimate.value = null;
    }
  }

  bool get hasEstimate => estimate.value != null;

  double get estimatedAnnualNet {
    final e = estimate.value;
    if (e == null) return 0;
    return (e.expectedMonthlyIncome - e.expectedMonthlyExpense) * 12;
  }

  double get estimatedInvestment {
    final e = estimate.value;
    if (e == null) return 0;
    return e.purchaseCost + e.renovationCost;
  }

  double get estimatedRoiPercent {
    final investment = estimatedInvestment;
    if (investment <= 0) return 0;
    return (estimatedAnnualNet / investment) * 100;
  }
}
