import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/rent_portfolio_metrics.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/local/service/workspace_context_service.dart';
import '../../../../routes/app_pages.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

/// Portfolio listing row for the hub carousel.
/// Kept for backward compatibility in the view; populated from real data only.
class RentHubListingItem {
  const RentHubListingItem({
    required this.hubId,
    required this.imageAsset,
    required this.categoryLabel,
    required this.title,
    required this.monthlyRentLabel,
    this.occupied = true,
  });

  final String hubId;
  final String imageAsset;
  final String categoryLabel;
  final String title;
  final String monthlyRentLabel;
  final bool occupied;
}

class RentHubController extends BaseController {
  RentHubController({
    IncomeLocalDataSource? incomeLocal,
    ExpenseLocalDataSource? expenseLocal,
    PropertyLocalDataSource? propertyLocal,
    TenantLocalDataSource? tenantLocal,
    PreferenceManager? preferenceManager,
    WorkspaceContextService? workspaceContext,
  })  : _incomeLocal = incomeLocal ?? Get.find<IncomeLocalDataSource>(),
        _expenseLocal = expenseLocal ?? Get.find<ExpenseLocalDataSource>(),
        _propertyLocal = propertyLocal ?? Get.find<PropertyLocalDataSource>(),
        _tenantLocal = tenantLocal ?? Get.find<TenantLocalDataSource>(),
        _preferenceManager = preferenceManager ??
            Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        workspaceContext = workspaceContext ?? Get.find<WorkspaceContextService>();

  static const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService workspaceContext;

  final _chartIncome = List<double>.filled(7, 0).obs;
  final _chartExpense = List<double>.filled(7, 0).obs;
  final _incomeTotal = 0.0.obs;
  final _expenseTotal = 0.0.obs;
  final _profitTrendPercent = 0.0.obs;
  final _monthlyIncome = 0.0.obs;
  final _occupancyPercent = 0.obs;
  final _activeLeases = 0.obs;
  final _totalArrears = 0.0.obs;

  final listings = <RentHubListingItem>[].obs;

  List<double> get chartIncome => _chartIncome;
  List<double> get chartExpense => _chartExpense;

  CurrencyService get _currency => Get.find<CurrencyService>();

  String get netProfitLabel =>
      _currency.formatBase((_incomeTotal.value - _expenseTotal.value).round());
  String get totalIncomeLabel => _currency.formatBase(_incomeTotal.value.round());
  String get expensesLabel => _currency.formatBase(_expenseTotal.value.round());
  String get profitTrendLabel {
    final p = _profitTrendPercent.value;
    final sign = p > 0 ? '+' : '';
    return '$sign${p.toStringAsFixed(1)}%';
  }

  String get monthlyIncomeLabel =>
      _currency.formatBase(_monthlyIncome.value.round());
  String get occupancyLabel => '${_occupancyPercent.value}%';
  String get activeLeasesLabel => '${_activeLeases.value}';
  String get totalArrearsLabel =>
      _currency.formatBase(_totalArrears.value.round());

  String _formatStoredRentLabel(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', ''));
    if (parsed != null) {
      return _currency.formatBase(parsed.round());
    }
    return raw.trim();
  }

  final selectedBottomNavIndex = 0.obs;

  @override
  void onReady() {
    super.onReady();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final incomeRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenseRows = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');

    var incomeTotal = 0.0;
    var expenseTotal = 0.0;
    final weekIncome = List<double>.filled(7, 0);
    final weekExpense = List<double>.filled(7, 0);
    var thisMonthIncome = 0.0;
    var thisMonthExpense = 0.0;
    var lastMonthIncome = 0.0;
    var lastMonthExpense = 0.0;

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 1);

    for (final row in incomeRows) {
      final d = _safeDate(row.datePaidIso, row.createdAtMs);
      incomeTotal += row.amountValue;
      if (!d.isBefore(weekStart) && !d.isAfter(today)) {
        weekIncome[differenceInDays(weekStart, d)] += row.amountValue;
      }
      if (!d.isBefore(thisMonthStart) && d.isBefore(thisMonthEnd)) {
        thisMonthIncome += row.amountValue;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastMonthIncome += row.amountValue;
      }
    }

    for (final row in expenseRows) {
      final d = _safeDate(row.datePaidIso, row.createdAtMs);
      expenseTotal += row.amountValue;
      if (!d.isBefore(weekStart) && !d.isAfter(today)) {
        weekExpense[differenceInDays(weekStart, d)] += row.amountValue;
      }
      if (!d.isBefore(thisMonthStart) && d.isBefore(thisMonthEnd)) {
        thisMonthExpense += row.amountValue;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastMonthExpense += row.amountValue;
      }
    }

    final thisNet = thisMonthIncome - thisMonthExpense;
    final lastNet = lastMonthIncome - lastMonthExpense;
    final trend = lastNet.abs() < 0.01 ? (thisNet == 0 ? 0.0 : 100.0) : ((thisNet - lastNet) / lastNet.abs()) * 100.0;

    _incomeTotal.value = incomeTotal;
    _expenseTotal.value = expenseTotal;
    _chartIncome.assignAll(weekIncome);
    _chartExpense.assignAll(weekExpense);
    _profitTrendPercent.value = trend;

    final userId = (await _preferenceManager.getUser()).id ?? '';
    final workspaceType = await workspaceContext.getWorkspaceType();
    final propertyRows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspaceType,
    );
    final rentProperties =
        propertyRows.where((p) => p.workspaceType.trim().toLowerCase() == 'rent');
    listings.assignAll(
      rentProperties.map((p) {
        return RentHubListingItem(
          hubId: p.propertyRef.trim().isNotEmpty ? p.propertyRef.trim() : 'legacy_${p.id}',
          imageAsset: '',
          categoryLabel: p.propertyType.toUpperCase(),
          title: p.propertyName.trim().isNotEmpty
              ? p.propertyName
              : p.propertyLocation,
          monthlyRentLabel: p.rentAmount.trim().isEmpty
              ? CurrencyService.zeroLabel()
              : _formatStoredRentLabel(p.rentAmount),
          occupied: true,
        );
      }),
    );

    final tenants = await _tenantLocal.getAllNewestFirstByWorkspace('rent');
    final portfolio = await RentPortfolioMetricsCalculator.compute(
      properties: rentProperties.toList(),
      tenants: tenants,
      incomeRows: incomeRows,
      now: now,
    );
    _monthlyIncome.value = portfolio.monthlyIncome;
    _occupancyPercent.value = portfolio.occupancyPercent;
    _activeLeases.value = portfolio.activeLeases;
    _totalArrears.value = portfolio.totalArrears;
  }

  void onBottomNavTap(int index) => selectedBottomNavIndex.value = index;

  void onAddBooking() {}

  void onViewAllProperties() {}

  void onListingTap(RentHubListingItem item) {}

  void onReadManagementTips() {}

  void onConciergeSupportTap() {}

  Future<void> openAddExpense() async {
    final saved = await Get.toNamed(Routes.ADD_EXPENSE);
    if (saved == true) {
      await refreshDashboard();
    }
  }

  Future<void> openAddIncome() async {
    final saved = await Get.toNamed(Routes.RECORD_PAYMENT);
    if (saved == true) {
      await refreshDashboard();
      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
    }
  }

  void openTenancyInsights() => Get.toNamed(
        Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
        parameters: const {'ws': 'rent'},
        arguments: const {'ws': 'rent'},
      );

  void openManagePayments() => Get.toNamed(Routes.RENT_MANAGE_PAYMENTS);

  Future<void> openHostDashboard() async {
    final hostName = (await _preferenceManager.getString(
      PreferenceManager.keyFullName,
      defaultValue: '',
    ))
        .trim();
    Get.toNamed(
      Routes.RENT_HOST_DASHBOARD_PAYMENT_ALERTS,
      parameters: {if (hostName.isNotEmpty) 'hostName': hostName},
    );
  }

  int differenceInDays(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays.clamp(0, 6);
  }

  DateTime _safeDate(String iso, int createdAtMs) {
    try {
      final parsed = DateTime.parse(iso);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      final fromMs = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
      return DateTime(fromMs.year, fromMs.month, fromMs.day);
    }
  }
}
