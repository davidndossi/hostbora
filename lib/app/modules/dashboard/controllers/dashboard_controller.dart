import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/community.dart';
import '../../../data/model/user_community.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends BaseController {

  final isLoading = true.obs;
  final isMember = false.obs;
  final isLeader = false.obs;
  final isAdmin = false.obs;
  final showList = false.obs;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final IncomeLocalDataSource _incomeLocal = Get.find<IncomeLocalDataSource>();
  final ExpenseLocalDataSource _expenseLocal =
      Get.find<ExpenseLocalDataSource>();

  static final _money = NumberFormat('#,###', 'en_US');

  late String firebaseToken;
  Timer? _debounce;

  // Communities + filters (for dashboard context)
  final communities = <Community>[].obs;
  final filteredCommunities = <Community>[].obs;
  final selectedCommunity = Rxn<Community>();
  final communitySearch = ''.obs;
  final communitySearchController = TextEditingController();

  // Community member directory
  final members = <UserCommunity>[].obs;
  final filteredMembers = <UserCommunity>[].obs;
  final memberSearch = ''.obs;
  final memberRoleFilter = ''.obs; // '' means all
  final memberStatusFilter = ''.obs; // '' means all

  // Stats are dynamic and fetched per community
  final stats = <Map<String, dynamic>>[].obs;

  final isIncomeSelected = true.obs;

  // Metric card data (Income view) – from local DB
  final totalRevenue = 'TZS 0'.obs;
  final totalRevenueChange = '+0%'.obs;
  final totalRevenueUp = true.obs;

  final avgDailyRate = 'TZS 0'.obs;
  final avgDailyRateChange = '+0%'.obs;
  final avgDailyRateUp = true.obs;

  final netProfit = 'TZS 0'.obs;
  final netProfitChange = '+0%'.obs;
  final netProfitUp = true.obs;

  // Performance trends – scaled for fixed chart axis (dashboard_view)
  final currentTrendValues = <double>[0, 0, 0, 0].obs;
  final previousTrendValues = <double>[0, 0, 0, 0].obs;
  final currentExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  final previousExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  static const trendLabels = ['WEEK 1', 'WEEK 2', 'WEEK 3', 'WEEK 4'];

  // Monthly: A = revenue, B = expenses – from local DB
  final monthlyLabels = <String>['MAR', 'APR', 'MAY', 'JUN', 'JUL'].obs;
  final monthlyValuesA = <double>[0, 0, 0, 0, 0].obs;
  final monthlyValuesB = <double>[0, 0, 0, 0, 0].obs;

  // Expense metrics – from local DB
  final totalExpenses = 'TZS 0'.obs;
  final totalExpensesChange = '+0%'.obs;
  final totalExpensesUp = true.obs;
  final avgDailyExpense = 'TZS 0'.obs;
  final avgDailyExpenseChange = '+0%'.obs;
  final avgDailyExpenseUp = true.obs;

  @override
  void onInit() {
    _bootstrap();
    loadDashboard();
    super.onInit();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    communitySearchController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await getFirebaseToken();
    isAdmin(await _preferenceManager.getBool('isAdmin'));
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      const ws = 'bnb';
      final incomes =
          await _incomeLocal.getAllNewestFirst(workspaceType: ws);
      final expenses =
          await _expenseLocal.getAllNewestFirst(workspaceType: ws);

      logger.d(
        'Dashboard loadDashboard workspace=$ws '
        'incomeRows=${incomes.length} expenseRows=${expenses.length}',
      );
      final incomeSumAll =
          incomes.fold<double>(0, (a, r) => a + r.amountValue);
      final expenseSumAll =
          expenses.fold<double>(0, (a, r) => a + r.amountValue);
      logger.d(
        'Dashboard DB totals (all dates, workspace slice): '
        'income=$incomeSumAll expenses=$expenseSumAll',
      );
      for (final r in incomes) {
        logger.d(
          'Dashboard income id=${r.id} amount=${r.amountValue} '
          'datePaid=${r.datePaidIso} category=${r.category} '
          'workspace=${r.workspaceType}',
        );
      }
      for (final r in expenses) {
        logger.d(
          'Dashboard expense id=${r.id} amount=${r.amountValue} '
          'datePaid=${r.datePaidIso} category=${r.category} '
          'workspace=${r.workspaceType}',
        );
      }

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);

      final daysThisMonth = nextMonthStart.difference(thisMonthStart).inDays;
      final daysLastMonth = thisMonthStart.difference(lastMonthStart).inDays;

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

      final revThis = sumIncomeBetween(thisMonthStart, nextMonthStart);
      final revLast = sumIncomeBetween(lastMonthStart, thisMonthStart);
      final expThis = sumExpenseBetween(thisMonthStart, nextMonthStart);
      final expLast = sumExpenseBetween(lastMonthStart, thisMonthStart);

      totalRevenue.value = 'TZS ${_money.format(revThis.round())}';
      totalRevenueChange.value = _pctChange(revThis, revLast);
      totalRevenueUp.value = revThis >= revLast;

      final avgDailyThis =
          daysThisMonth > 0 ? revThis / daysThisMonth : 0.0;
      final avgDailyLast =
          daysLastMonth > 0 ? revLast / daysLastMonth : 0.0;
      avgDailyRate.value = 'TZS ${_money.format(avgDailyThis.round())}';
      avgDailyRateChange.value = _pctChange(avgDailyThis, avgDailyLast);
      avgDailyRateUp.value = avgDailyThis >= avgDailyLast;

      final profitThis = revThis - expThis;
      final profitLast = revLast - expLast;
      netProfit.value = 'TZS ${_money.format(profitThis.round())}';
      netProfitChange.value = _pctChange(profitThis, profitLast);
      netProfitUp.value = profitThis >= profitLast;

      totalExpenses.value = 'TZS ${_money.format(expThis.round())}';
      totalExpensesChange.value = _pctChange(expThis, expLast);
      totalExpensesUp.value = expThis >= expLast;

      final avgExpDailyThis =
          daysThisMonth > 0 ? expThis / daysThisMonth : 0.0;
      final avgExpDailyLast =
          daysLastMonth > 0 ? expLast / daysLastMonth : 0.0;
      avgDailyExpense.value = 'TZS ${_money.format(avgExpDailyThis.round())}';
      avgDailyExpenseChange.value =
          _pctChange(avgExpDailyThis, avgExpDailyLast);
      avgDailyExpenseUp.value = avgExpDailyThis >= avgExpDailyLast;

      final curIncomeQuarters = _quarterlySumsInMonth(
        incomes,
        thisMonthStart,
        daysThisMonth,
        _dayIncome,
      );
      final prevIncomeQuarters = _quarterlySumsInMonth(
        incomes,
        lastMonthStart,
        daysLastMonth,
        _dayIncome,
      );
      _assignScaledTrends(
        curIncomeQuarters,
        prevIncomeQuarters,
        currentTrendValues,
        previousTrendValues,
      );

      final curExpQuarters = _quarterlySumsInMonth(
        expenses,
        thisMonthStart,
        daysThisMonth,
        _dayExpense,
      );
      final prevExpQuarters = _quarterlySumsInMonth(
        expenses,
        lastMonthStart,
        daysLastMonth,
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
      for (var i = 4; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final mNext = DateTime(m.year, m.month + 1, 1);
        labels.add(DateFormat('MMM').format(m).toUpperCase());
        monthlyA.add(sumIncomeBetween(m, mNext));
        monthlyB.add(sumExpenseBetween(m, mNext));
      }
      monthlyLabels.assignAll(labels);
      monthlyValuesA.assignAll(monthlyA);
      monthlyValuesB.assignAll(monthlyB);
    } catch (_) {
      // keep default/placeholder values
    } finally {
      isLoading.value = false;
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

  /// Four buckets within [monthStart]'s month (week-style chart; Y scaled to 0–6 in UI).
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
    outCurrent.assignAll(
      current.map((e) => e * scale).take(4).toList(),
    );
    outPrevious.assignAll(
      previous.map((e) => e * scale).take(4).toList(),
    );
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

  void recordPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void addExpense() => Get.toNamed(Routes.ADD_EXPENSE);

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

}