import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/property_break_even_metrics.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/rent_property_estimate_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../routes/app_pages.dart';

/// ROI for a single property passed via `propertyRef` / `propertyLabel`.
class RentPropertyRoiAnalysisController extends BaseController {
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
  final loading = false.obs;
  final propertyIncomeTotal = 0.0.obs;
  final propertyMaintenanceTotal = 0.0.obs;
  final propertyExpenseTotal = 0.0.obs;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String get displayPropertyTitle {
    final label = selectedPropertyLabel.value.trim();
    if (label.isNotEmpty) return label;
    final ref = selectedPropertyRef.value.trim();
    return ref.isEmpty ? (_isSw ? 'Mali' : 'Property') : ref;
  }

  @override
  void onReady() {
    super.onReady();
    selectedPropertyRef.value = (Get.parameters['propertyRef'] ?? '').trim();
    selectedPropertyLabel.value = (Get.parameters['propertyLabel'] ?? '').trim();
    final args = Get.arguments;
    if (args is Map) {
      if (selectedPropertyRef.value.isEmpty) {
        selectedPropertyRef.value =
            (args['propertyRef'] ?? '').toString().trim();
      }
      if (selectedPropertyLabel.value.isEmpty) {
        selectedPropertyLabel.value =
            (args['propertyLabel'] ?? args['propertyTitle'] ?? '')
                .toString()
                .trim();
      }
    }
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      await _resolvePropertyLabelIfNeeded();
      await _loadEstimate();
      await _loadPropertyScopedTotals();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _resolvePropertyLabelIfNeeded() async {
    if (selectedPropertyLabel.value.trim().isNotEmpty) return;
    final ref = selectedPropertyRef.value.trim();
    if (ref.isEmpty) return;
    final all = await _propertyLocal.getAllNewestFirst();
    for (final p in all) {
      final pref = p.propertyRef.trim();
      final local = 'local_${p.id}';
      if (pref != ref && local != ref) continue;
      final loc = p.propertyLocation.trim();
      final name = p.propertyName.trim();
      selectedPropertyLabel.value = loc.isNotEmpty
          ? (name.isNotEmpty ? '$loc · $name' : loc)
          : (name.isNotEmpty ? name : ref);
      return;
    }
  }

  Future<void> _loadEstimate() async {
    final ref = selectedPropertyRef.value.trim();
    if (ref.isEmpty) {
      estimate.value = null;
      return;
    }
    estimate.value = await _estimateLocal.findByPropertyRef(ref);
  }

  bool get hasEstimate => estimate.value != null;

  /// Purchase + renovation for the selected property.
  double get principalInvestment {
    final e = estimate.value;
    if (e == null) return 0;
    return e.purchaseCost + e.renovationCost;
  }

  double get acquisitionCost => estimate.value?.purchaseCost ?? 0;

  double get renovationCommitted => estimate.value?.renovationCost ?? 0;

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

  double get yieldToDatePercent {
    final p = principalInvestment;
    if (p <= 0) return 0;
    return (propertyIncomeTotal.value / p) * 100;
  }

  double get incomeForProperty => propertyIncomeTotal.value;

  double get maintenanceActual => propertyMaintenanceTotal.value;

  /// Prefer estimate annual expense; fall back to actual maintenance spend.
  double get maintenanceForChart {
    final e = estimate.value;
    if (e != null && e.expectedMonthlyExpense > 0) {
      return e.expectedMonthlyExpense * 12;
    }
    return maintenanceActual;
  }

  double get monthlyNetForBreakEven {
    final e = estimate.value;
    if (e == null) return 0;
    final income = propertyIncomeTotal.value;
    final monthlyActual = income > 0 ? income / 12 : 0.0;
    final monthlyIncome =
        monthlyActual > 0 ? monthlyActual : e.expectedMonthlyIncome;
    final monthlyExpense = e.expectedMonthlyExpense > 0
        ? e.expectedMonthlyExpense
        : (maintenanceActual / 12).clamp(0, double.infinity);
    return monthlyIncome - monthlyExpense;
  }

  String get breakEvenLabel {
    final principal = principalInvestment;
    final maintenance = maintenanceForChart;
    final totalCost = principal + (maintenance > 0 ? maintenance : 0);
    return PropertyBreakEvenMetrics.formatBreakEven(
      principalCost: totalCost > 0 ? totalCost : principal,
      monthlyNetIncome: monthlyNetForBreakEven,
      incomeGeneratedToDate: propertyIncomeTotal.value,
      isSw: _isSw,
    );
  }

  bool get showCostVsIncomeChart =>
      hasEstimate &&
      (principalInvestment > 0 ||
          maintenanceForChart > 0 ||
          incomeForProperty > 0);

  Future<void> _loadPropertyScopedTotals() async {
    final ref = selectedPropertyRef.value.trim();
    final label = selectedPropertyLabel.value.trim();
    if (ref.isEmpty && label.isEmpty) {
      propertyIncomeTotal.value = 0;
      propertyMaintenanceTotal.value = 0;
      propertyExpenseTotal.value = 0;
      return;
    }

    final incomeRows = ref.isNotEmpty
        ? await _incomeLocal.getAllByPropertyRefAndWorkspace(
            propertyRef: ref,
            workspaceType: 'rent',
          )
        : await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenseRows =
        await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
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
    }

    var maintenance = 0.0;
    var allExpense = 0.0;
    for (final row in expenseRows) {
      if (!_expenseMatchesProperty(
        row,
        ref: ref,
        label: label,
        tenants: tenants,
      )) {
        continue;
      }
      allExpense += row.amountValue;
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
    propertyExpenseTotal.value = allExpense;
  }

  bool _tenantMatchesScope(
    TenantRecord t, {
    required String ref,
    required String label,
  }) {
    if (ref.isNotEmpty && t.propertyRef.trim() == ref) return true;
    final pl = t.propertyLabel.trim();
    if (label.isNotEmpty && pl == label) return true;
    if (ref.isNotEmpty && pl.toLowerCase().contains(ref.toLowerCase())) {
      return true;
    }
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

  Future<void> openEstimateForm() async {
    final ref = selectedPropertyRef.value.trim();
    if (ref.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Hakuna kitambulisho cha mali.'
            : 'No property reference available.',
      );
      return;
    }
    final result = await Get.toNamed(
      Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
      parameters: {
        'propertyRef': ref,
        'propertyLabel': selectedPropertyLabel.value,
      },
    );
    if (result == true) await loadAll();
  }
}
