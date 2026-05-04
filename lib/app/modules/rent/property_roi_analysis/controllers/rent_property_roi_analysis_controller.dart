import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_property_estimate_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentPropertyRoiAnalysisController extends BaseController
    with RentRealDataControllerMixin {
  RentPropertyRoiAnalysisController()
      : _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>();

  final RentPropertyEstimateLocalDataSource _estimateLocal;
  final PropertyLocalDataSource _propertyLocal;

  final selectedPropertyLabel = ''.obs;
  final selectedPropertyRef = ''.obs;
  final estimate = Rxn<RentPropertyEstimateRecord>();
  final portfolio = <PropertyRecord>[].obs;
  final trendRangeIndex = 2.obs; // reserved for future granularity

  @override
  void onReady() {
    super.onReady();
    selectedPropertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    selectedPropertyLabel.value = (Get.parameters['propertyLabel'] ?? '').trim();
    loadAll();
  }

  Future<void> loadAll() async {
    await loadRealDataSnapshot();
    await _loadEstimate();
    await _loadPortfolio();
  }

  Future<void> _loadEstimate() async {
    if (selectedPropertyRef.value.isNotEmpty) {
      estimate.value = await _estimateLocal.findByPropertyRef(selectedPropertyRef.value);
    } else {
      estimate.value = null;
    }
  }

  Future<void> _loadPortfolio() async {
    final rows = await _propertyLocal.getAllNewestFirst();
    portfolio.assignAll(rows.take(8).toList());
  }

  bool get hasEstimate => estimate.value != null;

  /// Purchase + renovation for the selected property estimate (principal deployed).
  double get principalInvestment {
    final e = estimate.value;
    if (e == null) return 0;
    return e.purchaseCost + e.renovationCost;
  }

  double get acquisitionCost => estimate.value?.purchaseCost ?? 0;

  double get renovationCommitted => estimate.value?.renovationCost ?? 0;

  /// Renovation “utilized” — heuristic: share of portfolio expenses when estimate exists.
  double renovationUtilized(double expenseTotal) {
    if (renovationCommitted <= 0) return 0;
    final cap = renovationCommitted;
    final guess = expenseTotal * 0.22;
    if (guess > cap) return cap;
    return guess;
  }

  double get estimatedAnnualNet {
    final e = estimate.value;
    if (e == null) return 0;
    return (e.expectedMonthlyIncome - e.expectedMonthlyExpense) * 12;
  }

  double get estimatedRoiPercent {
    final inv = principalInvestment;
    if (inv <= 0) return 0;
    return (estimatedAnnualNet / inv) * 100;
  }

  double yieldToDatePercent(double incomeTotal) {
    final p = principalInvestment;
    if (p <= 0) return 0;
    return (incomeTotal / p) * 100;
  }

  String? roiLabelForProperty(PropertyRecord p) {
    if (hasEstimate &&
        p.propertyRef.trim().isNotEmpty &&
        p.propertyRef.trim() == selectedPropertyRef.value.trim()) {
      return '${estimatedRoiPercent.toStringAsFixed(1)}%';
    }
    return null;
  }

  void setTrendRange(int index) {
    trendRangeIndex.value = index.clamp(0, 2);
  }

  /// Quarterly splits for chart (fiscal display); smooths [totalIncome] across Q1–Q4.
  List<double> quarterlyIncomeSeries(double totalIncome) {
    if (totalIncome <= 0) return [0, 0, 0, 0];
    final q = totalIncome / 4;
    return [
      q * 0.88,
      q * 1.05,
      q * 0.97,
      q * 1.10,
    ];
  }

  List<double> quarterlyInvestmentSeries(double principal) {
    if (principal <= 0) return [0, 0, 0, 0];
    final q = principal / 4;
    return [q, q, q, q];
  }
}
