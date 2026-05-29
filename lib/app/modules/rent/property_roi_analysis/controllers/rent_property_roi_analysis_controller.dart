import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/property_break_even_metrics.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/rent_property_estimate_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentPropertyRoiAnalysisController extends BaseController
    with RentRealDataControllerMixin {
  RentPropertyRoiAnalysisController()
      : _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>();

  final RentPropertyEstimateLocalDataSource _estimateLocal;
  final PropertyLocalDataSource _propertyLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final TenantLocalDataSource _tenantLocal;

  final selectedPropertyLabel = ''.obs;
  final selectedPropertyRef = ''.obs;
  final estimate = Rxn<RentPropertyEstimateRecord>();
  final portfolio = <PropertyRecord>[].obs;
  final trendRangeIndex = 2.obs; // reserved for future granularity
  final propertyIncomeTotal = 0.0.obs;
  final propertyMaintenanceTotal = 0.0.obs;

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
    await _loadPropertyScopedTotals();
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

  /// Estimated annual maintenance / operating budget from estimate.
  double get maintenanceEstimateAnnual {
    final e = estimate.value;
    if (e == null) return 0;
    return e.expectedMonthlyExpense * 12;
  }

  /// Maintenance slice for charts — estimate wins, else actual maintenance spend.
  double get maintenanceCostForChart {
    if (maintenanceEstimateAnnual > 0) return maintenanceEstimateAnnual;
    return propertyMaintenanceTotal.value;
  }

  double get incomeForProperty => propertyIncomeTotal.value;

  double get monthlyNetForBreakEven {
    final e = estimate.value;
    if (e == null) return 0;
    final monthsObserved = _monthsWithIncomeObserved();
    final monthlyActual =
        monthsObserved > 0 ? propertyIncomeTotal.value / monthsObserved : 0.0;
    final monthlyIncome =
        monthlyActual > 0 ? monthlyActual : e.expectedMonthlyIncome;
    final monthlyExpense = e.expectedMonthlyExpense > 0
        ? e.expectedMonthlyExpense
        : (propertyMaintenanceTotal.value / 12).clamp(0, double.infinity);
    return monthlyIncome - monthlyExpense;
  }

  String get breakEvenLabel {
    final principal = principalInvestment;
    final maintenance = maintenanceCostForChart;
    final totalCost = principal + (maintenance > 0 ? maintenance : 0);
    return PropertyBreakEvenMetrics.formatBreakEven(
      principalCost: totalCost > 0 ? totalCost : principal,
      monthlyNetIncome: monthlyNetForBreakEven,
      incomeGeneratedToDate: propertyIncomeTotal.value,
      isSw: Get.locale?.languageCode == 'sw',
    );
  }

  bool get showPrincipalVsIncomeChart =>
      hasEstimate && (principalInvestment > 0 || maintenanceEstimateAnnual > 0);

  int _monthsWithIncomeObserved() {
    final ref = selectedPropertyRef.value.trim();
    if (ref.isEmpty) return 0;
    return 12;
  }

  Future<void> _loadPropertyScopedTotals() async {
    final ref = selectedPropertyRef.value.trim();
    final label = selectedPropertyLabel.value.trim();
    if (ref.isEmpty && label.isEmpty) {
      propertyIncomeTotal.value = 0;
      propertyMaintenanceTotal.value = 0;
      return;
    }

    final incomeRows = ref.isNotEmpty
        ? await _incomeLocal.getAllByPropertyRefAndWorkspace(
            propertyRef: ref,
            workspaceType: 'rent',
          )
        : await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenseRows = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final tenants = await _tenantLocal.getAllNewestFirst();

    var income = 0.0;
    if (ref.isNotEmpty) {
      income = incomeRows.fold<double>(0, (s, r) => s + r.amountValue);
    }
    if (income <= 0) {
      for (final t in tenants) {
        if (!_tenantMatchesScope(t, ref: ref, label: label)) continue;
        for (final row in incomeRows) {
          if (_incomeMatchesTenant(row, t)) income += row.amountValue;
        }
      }
      if (income <= 0 && ref.isEmpty) {
        income = incomeRows.fold<double>(0, (s, r) => s + r.amountValue);
      }
    }

    var maintenance = 0.0;
    for (final row in expenseRows) {
      if (!_expenseMatchesProperty(row, ref: ref, label: label, tenants: tenants)) {
        continue;
      }
      final cat = row.category.trim().toLowerCase();
      if (cat.contains('maint') ||
          cat.contains('repair') ||
          cat.contains('plumb') ||
          cat.contains('electr')) {
        maintenance += row.amountValue;
      }
    }

    propertyIncomeTotal.value = income;
    propertyMaintenanceTotal.value = maintenance;
  }

  bool _tenantMatchesScope(
    TenantRecord t, {
    required String ref,
    required String label,
  }) {
    if (ref.isNotEmpty && t.propertyRef.trim() == ref) return true;
    final pl = t.propertyLabel.trim();
    if (label.isNotEmpty && pl == label) return true;
    if (ref.isNotEmpty && pl.toLowerCase().contains(ref.toLowerCase())) return true;
    return false;
  }

  bool _incomeMatchesTenant(IncomeRecord income, TenantRecord tenant) {
    if (income.tenantName.trim().toLowerCase() !=
        tenant.tenantName.trim().toLowerCase()) {
      return false;
    }
    final tenantRef = tenant.propertyRef.trim();
    final incomeRef = income.propertyRef.trim();
    if (tenantRef.isNotEmpty &&
        incomeRef.isNotEmpty &&
        tenantRef != incomeRef) {
      return false;
    }
    return true;
  }

  bool _expenseMatchesProperty(
    ExpenseRecord expense, {
    required String ref,
    required String label,
    required List<TenantRecord> tenants,
  }) {
    if (ref.isNotEmpty) {
      for (final t in tenants) {
        if (t.propertyRef.trim() != ref) continue;
        if (_expenseMatchesTenant(expense, t)) return true;
      }
    }
    final pl = label.trim().toLowerCase();
    if (pl.isEmpty) return false;
    final ap = expense.apartment.trim().toLowerCase();
    final unit = expense.apartmentUnit.trim().toLowerCase();
    final notes = expense.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) || pl.contains(ap) || ap == pl;
  }

  bool _expenseMatchesTenant(ExpenseRecord expense, TenantRecord tenant) {
    final tenantName = tenant.tenantName.trim().toLowerCase();
    final expenseTenantName = expense.tenantName.trim().toLowerCase();
    if (expenseTenantName.isNotEmpty && expenseTenantName == tenantName) {
      return true;
    }
    final pl = tenant.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return false;
    final ap = expense.apartment.trim().toLowerCase();
    final unit = expense.apartmentUnit.trim().toLowerCase();
    final notes = expense.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) || pl.contains(ap) || ap == pl;
  }
}
