import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../routes/app_pages.dart';
import '../../rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';

class FinancialOverviewController extends BaseController {
  FinancialOverviewController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>();

  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final TenantLocalDataSource _tenantLocal;

  final isLoading = true.obs;
  final isIncomeSelected = true.obs;

  final totalRevenue = ''.obs;
  final totalRevenueChange = '+0%'.obs;
  final totalRevenueUp = true.obs;

  final avgDailyRate = ''.obs;
  final avgDailyRateChange = '+0%'.obs;
  final avgDailyRateUp = true.obs;

  final netProfit = ''.obs;
  final netProfitChange = '+0%'.obs;
  final netProfitUp = true.obs;

  final currentTrendValues = <double>[0, 0, 0, 0].obs;
  final previousTrendValues = <double>[0, 0, 0, 0].obs;
  final currentExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  final previousExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  static const trendLabels = ['WEEK 1', 'WEEK 2', 'WEEK 3', 'WEEK 4'];

  final monthlyLabels = <String>[].obs;
  final monthlyValuesA = <double>[].obs;
  final monthlyValuesB = <double>[].obs;

  final totalExpenses = ''.obs;
  final totalExpensesChange = '+0%'.obs;
  final totalExpensesUp = true.obs;

  final avgDailyExpense = ''.obs;
  final avgDailyExpenseChange = '+0%'.obs;
  final avgDailyExpenseUp = true.obs;

  /// When both are set, KPIs and trend charts use this inclusive range (end date inclusive).
  final customRangeStart = Rxn<DateTime>();
  final customRangeEndInclusive = Rxn<DateTime>();

  final _chartIncome = List<double>.filled(7, 0).obs;
  final _chartExpense = List<double>.filled(7, 0).obs;
  final _incomeTotal = 0.0.obs;
  final _expenseTotal = 0.0.obs;
  final _profitTrendPercent = 0.0.obs;
  final _monthlyIncome = 0.0.obs;
  final _occupancyPercent = 0.obs;
  final _activeLeases = 0.obs;
  final _totalArrears = 0.0.obs;

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

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  @override
  void onInit() {
    super.onInit();
    loadOverview();
  }

  static Future<void> refreshIfRegistered() async {
    if (Get.isRegistered<FinancialOverviewController>()) {
      await Get.find<FinancialOverviewController>().loadOverview(quiet: true);
    }
  }

  Future<void> loadOverview({bool quiet = false}) async {
    if (!quiet) isLoading.value = true;
    try {
      final ws = 'both';
      final fx = Get.find<CurrencyService>();
      final incomes =
          await _incomeLocal.getAllNewestFirst(workspaceType: ws);
      final expenses =
          await _expenseLocal.getAllNewestFirst(workspaceType: ws);

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);

      late DateTime periodStart;
      late DateTime periodEndExclusive;
      late DateTime prevPeriodStart;
      late DateTime prevPeriodEndExclusive;

      final cs = customRangeStart.value;
      final ce = customRangeEndInclusive.value;
      if (cs != null && ce != null) {
        periodStart = DateTime(cs.year, cs.month, cs.day);
        periodEndExclusive =
            DateTime(ce.year, ce.month, ce.day).add(const Duration(days: 1));
        if (!periodEndExclusive.isAfter(periodStart)) {
          periodStart = thisMonthStart;
          periodEndExclusive = nextMonthStart;
          prevPeriodStart = lastMonthStart;
          prevPeriodEndExclusive = thisMonthStart;
        } else {
          final lenDays = periodEndExclusive.difference(periodStart).inDays;
          prevPeriodEndExclusive = periodStart;
          prevPeriodStart =
              periodStart.subtract(Duration(days: lenDays));
        }
      } else {
        periodStart = thisMonthStart;
        periodEndExclusive = nextMonthStart;
        prevPeriodStart = lastMonthStart;
        prevPeriodEndExclusive = thisMonthStart;
      }

      final daysThisPeriod =
          periodEndExclusive.difference(periodStart).inDays;
      final daysPrevPeriod =
          prevPeriodEndExclusive.difference(prevPeriodStart).inDays;

      double sumIncomeBetween(DateTime start, DateTime end) {
        var s = 0.0;
        for (final r in incomes) {
          final d = r.paidLocalCalendarOrCreated();
          if (!d.isBefore(start) && d.isBefore(end)) s += r.amountValue;
        }
        return s;
      }

      double sumExpenseBetween(DateTime start, DateTime end) {
        var s = 0.0;
        for (final r in expenses) {
          final d = _expenseCalendarDay(r);
          if (!d.isBefore(start) && d.isBefore(end)) s += r.amountValue;
        }
        return s;
      }

      final revThis = sumIncomeBetween(periodStart, periodEndExclusive);
      final revLast = sumIncomeBetween(prevPeriodStart, prevPeriodEndExclusive);
      final expThis = sumExpenseBetween(periodStart, periodEndExclusive);
      final expLast = sumExpenseBetween(prevPeriodStart, prevPeriodEndExclusive);

      totalRevenue.value = fx.formatBase(revThis.round());
      totalRevenueChange.value = _pctChange(revThis, revLast);
      totalRevenueUp.value = revThis >= revLast;

      final avgDailyThis =
          daysThisPeriod > 0 ? revThis / daysThisPeriod : 0.0;
      final avgDailyLast =
          daysPrevPeriod > 0 ? revLast / daysPrevPeriod : 0.0;
      avgDailyRate.value = fx.formatBase(avgDailyThis.round());
      avgDailyRateChange.value = _pctChange(avgDailyThis, avgDailyLast);
      avgDailyRateUp.value = avgDailyThis >= avgDailyLast;

      final profitThis = revThis - expThis;
      final profitLast = revLast - expLast;
      netProfit.value = fx.formatBase(profitThis.round());
      netProfitChange.value = _pctChange(profitThis, profitLast);
      netProfitUp.value = profitThis >= profitLast;

      totalExpenses.value = fx.formatBase(expThis.round());
      totalExpensesChange.value = _pctChange(expThis, expLast);
      totalExpensesUp.value = expThis >= expLast;

      final avgExpDailyThis =
          daysThisPeriod > 0 ? expThis / daysThisPeriod : 0.0;
      final avgExpDailyLast =
          daysPrevPeriod > 0 ? expLast / daysPrevPeriod : 0.0;
      avgDailyExpense.value = fx.formatBase(avgExpDailyThis.round());
      avgDailyExpenseChange.value =
          _pctChange(avgExpDailyThis, avgExpDailyLast);
      avgDailyExpenseUp.value = avgExpDailyThis >= avgExpDailyLast;

      final customRangeValid = cs != null &&
          ce != null &&
          DateTime(ce.year, ce.month, ce.day)
              .add(const Duration(days: 1))
              .isAfter(DateTime(cs.year, cs.month, cs.day));
      final useCustomRange = customRangeValid;
      final curIncomeQuarters = useCustomRange
          ? _quarterlySumsInDateRange(
              incomes,
              periodStart,
              periodEndExclusive,
              _dayIncome,
            )
          : _quarterlySumsInMonth(
              incomes,
              periodStart,
              daysThisPeriod,
              _dayIncome,
            );
      final prevIncomeQuarters = useCustomRange
          ? _quarterlySumsInDateRange(
              incomes,
              prevPeriodStart,
              prevPeriodEndExclusive,
              _dayIncome,
            )
          : _quarterlySumsInMonth(
              incomes,
              prevPeriodStart,
              daysPrevPeriod,
              _dayIncome,
            );
      _assignScaledTrends(
        curIncomeQuarters,
        prevIncomeQuarters,
        currentTrendValues,
        previousTrendValues,
      );

      final curExpQuarters = useCustomRange
          ? _quarterlySumsInDateRange(
              expenses,
              periodStart,
              periodEndExclusive,
              _dayExpense,
            )
          : _quarterlySumsInMonth(
              expenses,
              periodStart,
              daysThisPeriod,
              _dayExpense,
            );
      final prevExpQuarters = useCustomRange
          ? _quarterlySumsInDateRange(
              expenses,
              prevPeriodStart,
              prevPeriodEndExclusive,
              _dayExpense,
            )
          : _quarterlySumsInMonth(
              expenses,
              prevPeriodStart,
              daysPrevPeriod,
              _dayExpense,
            );
      _assignScaledTrends(
        curExpQuarters,
        prevExpQuarters,
        currentExpenseTrendValues,
        previousExpenseTrendValues,
      );

      final labels = <String>[];
      final monthlyA = <double>[];
      final monthlyB = <double>[];
      final anchor = ce ?? now;
      for (var i = 4; i >= 0; i--) {
        final m = DateTime(anchor.year, anchor.month - i, 1);
        final mNext = DateTime(m.year, m.month + 1, 1);
        labels.add(DateFormat('MMM').format(m).toUpperCase());
        monthlyA.add(sumIncomeBetween(m, mNext));
        monthlyB.add(sumExpenseBetween(m, mNext));
      }
      monthlyLabels.assignAll(labels);
      monthlyValuesA.assignAll(monthlyA);
      monthlyValuesB.assignAll(monthlyB);

      // Compute arrears across all tenants (expected rent - income received).
      await _computeArrears(incomes);
    } catch (_) {
      // Keep last loaded values on error.
    } finally {
      if (!quiet) isLoading.value = false;
    }
  }

  Future<void> _computeArrears(List<IncomeRecord> bnbIncomes) async {
    try {
      final tenants = await _tenantLocal.getAllNewestFirst();
      if (tenants.isEmpty) {
        _totalArrears.value = 0;
        return;
      }
      // Load rent income as well for full matching.
      final rentIncomes = await _incomeLocal.getAllNewestFirst(
        workspaceType: 'rent',
      );
      final allIncomes = [...bnbIncomes, ...rentIncomes];
      var arrears = 0.0;
      for (final t in tenants) {
        final due = TenantLedgerFinance.totalDueTsh(t).toDouble();
        if (due <= 0) continue;
        var paid = 0.0;
        for (final r in allIncomes) {
          if (TenantLedgerFinance.incomeMatchesTenant(r, t)) {
            paid += r.amountValue;
          }
        }
        final gap = due - paid;
        if (gap > 0) arrears += gap;
      }
      _totalArrears.value = arrears;
    } catch (_) {
      // Keep previous arrears value on error.
    }
  }

  DateTime _expenseCalendarDay(ExpenseRecord r) {
    final raw = r.datePaidIso.trim();
    if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
      final y = int.tryParse(raw.substring(0, 4));
      final m = int.tryParse(raw.substring(5, 7));
      final d = int.tryParse(raw.substring(8, 10));
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    try {
      final p = DateTime.parse(raw);
      return DateTime(p.year, p.month, p.day);
    } catch (_) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAtMs);
      return DateTime(dt.year, dt.month, dt.day);
    }
  }

  DateTime _dayIncome(IncomeRecord r) => r.paidLocalCalendarOrCreated();

  DateTime _dayExpense(ExpenseRecord r) => _expenseCalendarDay(r);

  /// Four buckets over [rangeStart, rangeEndExclusive) (same scaling as month quarters).
  List<double> _quarterlySumsInDateRange<T>(
    List<T> rows,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
    DateTime Function(T) dayOf,
  ) {
    final sums = [0.0, 0.0, 0.0, 0.0];
    final totalDays = rangeEndExclusive.difference(rangeStart).inDays;
    if (totalDays <= 0) return sums;
    final qSize = totalDays / 4.0;
    for (final row in rows) {
      final d = dayOf(row);
      if (d.isBefore(rangeStart) || !d.isBefore(rangeEndExclusive)) continue;
      final dayIndex = d.difference(rangeStart).inDays;
      final idx = math.min(3, (dayIndex / qSize).floor());
      final amount = row is IncomeRecord
          ? row.amountValue
          : (row as ExpenseRecord).amountValue;
      sums[idx] += amount;
    }
    return sums;
  }

  List<double> _quarterlySumsInMonth<T>(
    List<T> rows,
    DateTime monthStart,
    int daysInMonth,
    DateTime Function(T) dayOf,
  ) {
    final sums = [0.0, 0.0, 0.0, 0.0];
    if (daysInMonth <= 0) return sums;
    final qSize = daysInMonth / 4.0;
    for (final row in rows) {
      final d = dayOf(row);
      if (d.year != monthStart.year || d.month != monthStart.month) continue;
      final idx = math.min(3, ((d.day - 1) / qSize).floor());
      final amount = row is IncomeRecord
          ? row.amountValue
          : (row as ExpenseRecord).amountValue;
      sums[idx] += amount;
    }
    return sums;
  }

  void _assignScaledTrends(
    List<double> current,
    List<double> previous,
    RxList<double> outCurrent,
    RxList<double> outPrevious,
  ) {
    var maxV = 0.0;
    for (final v in current) {
      if (v > maxV) maxV = v;
    }
    for (final v in previous) {
      if (v > maxV) maxV = v;
    }
    final scale = maxV > 0 ? 6.0 / maxV : 1.0;
    outCurrent.assignAll(current.map((e) => e * scale).take(4).toList());
    outPrevious.assignAll(previous.map((e) => e * scale).take(4).toList());
    while (outCurrent.length < 4) {
      outCurrent.add(0);
    }
    while (outPrevious.length < 4) {
      outPrevious.add(0);
    }
  }

  String _pctChange(double current, double previous) {
    if (previous <= 0) {
      if (current <= 0) return '+0%';
      return '+100%';
    }
    final pct = ((current - previous) / previous) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.round()}%';
  }

  void goBack() => Get.back();

  void openCalendar() {
    final ctx = Get.context;
    if (ctx == null) return;
    final isSw = Get.locale?.languageCode == 'sw';
    Get.bottomSheet<void>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(
                isSw ? 'Mwezi huu (chaguo-msingi)' : 'Current month (default)',
              ),
              subtitle: Text(
                isSw
                    ? 'Futa kipindi maalum na tumia mwezi wa kalenda'
                    : 'Clear custom range and use calendar month',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Get.back<void>();
                customRangeStart.value = null;
                customRangeEndInclusive.value = null;
                loadOverview(quiet: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(isSw ? 'Chagua kipindi' : 'Choose date range'),
              subtitle: Text(
                isSw
                    ? 'Linganisha na kipindi cha muda sawa kabla'
                    : 'Compared to the same-length period before',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Get.back<void>();
                final now = DateTime.now();
                final initialStart = customRangeStart.value ??
                    DateTime(now.year, now.month, 1);
                final initialEnd = customRangeEndInclusive.value ??
                    DateTime(now.year, now.month, now.day);
                final picked = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(now.year - 3),
                  lastDate: DateTime(now.year + 1, 12, 31),
                  initialDateRange: DateTimeRange(
                    start: initialStart,
                    end: initialEnd,
                  ),
                  locale: const Locale('en', 'GB'),
                  helpText: isSw ? 'Chagua kipindi' : 'Select period',
                  saveText: isSw ? 'Tumia' : 'Apply',
                  cancelText: isSw ? 'Funga' : 'Close',
                );
                if (picked != null) {
                  customRangeStart.value = picked.start;
                  customRangeEndInclusive.value = picked.end;
                  await loadOverview(quiet: true);
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> recordPayment() async {
    final saved = await Get.toNamed(Routes.RECORD_PAYMENT);
    if (saved == true) {
      await loadOverview();
    }
  }

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

  void openManagePayments() => Get.toNamed(Routes.RENT_MANAGE_PAYMENTS);

  void openTenancyInsights() =>
      Get.toNamed(Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER);

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
}
