import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../routes/app_pages.dart';
import '../models/monthly_income_report_item.dart';

class MonthlyIncomeReportsController extends BaseController {
  MonthlyIncomeReportsController({
    IncomeLocalDataSource? incomeLocal,
    TenantLocalDataSource? tenantLocal,
    CurrencyService? currencyService,
  })  : _incomeLocal = incomeLocal ?? Get.find<IncomeLocalDataSource>(),
        _tenantLocal = tenantLocal ??
            (Get.isRegistered<TenantLocalDataSource>()
                ? Get.find<TenantLocalDataSource>()
                : null),
        _currency =
            currencyService ??
            (Get.isRegistered<CurrencyService>()
                ? Get.find<CurrencyService>()
                : null);

  final IncomeLocalDataSource _incomeLocal;
  final TenantLocalDataSource? _tenantLocal;
  final CurrencyService? _currency;

  final selectedYear = DateTime.now().year.obs;
  final isLoading = false.obs;
  final months = <MonthlyIncomeReportItem>[].obs;

  static final _monthTitle = DateFormat('MMMM yyyy');

  MonthlyIncomeReportItem? get featured {
    if (months.isEmpty) return null;
    return months.first;
  }

  List<MonthlyIncomeReportItem> get gridMonths {
    if (months.length <= 1) return const [];
    return months.sublist(1);
  }

  bool get canGoNextYear => selectedYear.value < DateTime.now().year;
  bool get canGoPrevYear => selectedYear.value > DateTime.now().year - 10;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['year'] is int) {
      selectedYear.value = args['year'] as int;
    }
    refreshYear();
  }

  Future<void> refreshYear() async {
    isLoading.value = true;
    try {
      final year = selectedYear.value;
      final incomes = await _incomeLocal.getAllNewestFirst();
      final tenants = await _safeTenants();

      final paidByMonth = <int, double>{};
      for (final row in incomes) {
        final d = row.paidLocalCalendarOrCreated();
        if (d.year != year) continue;
        paidByMonth[d.month] = (paidByMonth[d.month] ?? 0) + row.amountValue;
      }

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month);
      final lastMonth = (year == now.year) ? now.month : 12;
      final items = <MonthlyIncomeReportItem>[];
      for (var m = lastMonth; m >= 1; m--) {
        final monthStart = DateTime(year, m);
        final paid = paidByMonth[m] ?? 0;
        var upcoming = 0.0;
        // Upcoming only applies to the current month and future months.
        if (!monthStart.isBefore(currentMonthStart)) {
          final expected = _expectedRentForMonth(tenants, year, m);
          upcoming = (expected - paid).clamp(0, double.infinity);
        }
        items.add(
          MonthlyIncomeReportItem(
            month: monthStart,
            paidAmount: paid,
            upcomingAmount: upcoming,
          ),
        );
      }
      months.assignAll(items);
    } catch (_) {
      months.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<TenantRecord>> _safeTenants() async {
    final local = _tenantLocal;
    if (local == null) return const [];
    try {
      return await local.getAllNewestFirst();
    } catch (_) {
      return const [];
    }
  }

  /// Expected rent for one calendar month from active tenant lease terms.
  double _expectedRentForMonth(List<TenantRecord> tenants, int year, int month) {
    var total = 0.0;
    for (final t in tenants) {
      total += _expectedRentForTenantMonth(t, year, month);
    }
    return total;
  }

  static DateTime? _parseIsoDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  static bool _leaseIntersectsMonth(TenantRecord t, int year, int month) {
    final start = _parseIsoDate(t.leaseStartIso);
    final end = _parseIsoDate(t.leaseEndIso);
    final ms = DateTime(year, month, 1);
    final me = DateTime(year, month + 1, 0);
    if (start == null || end == null) return true;
    return !end.isBefore(ms) && !start.isAfter(me);
  }

  static double _expectedRentForTenantMonth(
    TenantRecord t,
    int year,
    int month,
  ) {
    if (!_leaseIntersectsMonth(t, year, month)) return 0;
    final start = _parseIsoDate(t.leaseStartIso);
    final end = _parseIsoDate(t.leaseEndIso);
    final ms = DateTime(year, month, 1);
    final me = DateTime(year, month + 1, 0);
    if (start == null || end == null) {
      return t.rentAmountValue <= 0 ? 0 : t.rentAmountValue;
    }
    final ovStart = start.isAfter(ms) ? start : ms;
    final ovEnd = end.isBefore(me) ? end : me;
    if (ovEnd.isBefore(ovStart)) return 0;
    final overlapDays = ovEnd.difference(ovStart).inDays + 1;
    final freq = t.rentFrequency.trim().toLowerCase();
    final r = t.rentAmountValue;
    if (r <= 0) return 0;
    switch (freq) {
      case 'per stay':
        if (start.year == year && start.month == month) return r;
        return 0;
      case 'per day':
        return r * overlapDays;
      case 'per week':
        return r * (overlapDays / 7).ceil();
      case 'per year':
        return r / 12;
      case 'per month':
      default:
        return r;
    }
  }

  String monthTitle(MonthlyIncomeReportItem item) =>
      _monthTitle.format(item.month);

  String formatAmount(double amount, {bool includeCode = false}) {
    final cs = _currency;
    if (cs != null) {
      final formatted = cs.formatBase(amount, decimalDigits: 2);
      if (!includeCode) return formatted.trim();
      return '${formatted.trim()} ${cs.baseCurrency.value}';
    }
    final n = NumberFormat('#,##0.00', 'en_US').format(amount);
    return includeCode ? '$n TZS' : n;
  }

  void prevYear() {
    if (!canGoPrevYear) return;
    selectedYear.value--;
    refreshYear();
  }

  void nextYear() {
    if (!canGoNextYear) return;
    selectedYear.value++;
    refreshYear();
  }

  void onAddIncome() {
    Get.toNamed(Routes.RECORD_PAYMENT)?.then((_) => refreshYear());
  }

  void openAnalyticsHub() {
    Get.toNamed(Routes.REPORTS_HUB);
  }

  void openMonthReport(MonthlyIncomeReportItem item) {
    Get.toNamed(
      Routes.REPORTS_HUB,
      arguments: {
        'year': item.year,
        'month': item.monthNumber,
        'initialTab': 1,
      },
    );
  }

  void goBack() => Get.back();
}
