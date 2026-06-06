import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../core/utils/rent_portfolio_metrics.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/model/community.dart';
import '../../../data/model/user_community.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

class DashboardController extends BaseController {

  final isLoading = true.obs;
  // final isMember = false.obs;
  // final isLeader = false.obs;
  // final isAdmin = false.obs;
  // final showList = false.obs;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final IncomeLocalDataSource _incomeLocal = Get.find<IncomeLocalDataSource>();
  final ExpenseLocalDataSource _expenseLocal =
      Get.find<ExpenseLocalDataSource>();
  final PropertyLocalDataSource _propertyLocal =
      Get.find<PropertyLocalDataSource>();
  final TenantLocalDataSource _tenantLocal = Get.find<TenantLocalDataSource>();
  final AppRepository _repository =
      Get.find<AppRepository>(tag: (AppRepository).toString());
  final PendingBookingsStore _pendingBookingsStore = PendingBookingsStore();
  late final BnbBookingPendingLoader _pendingBookingLoader =
      BnbBookingPendingLoader(
    syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
  );

  final isBnbWorkspace = true.obs;
  final bnbBookingsCount = 0.obs;
  final bnbGuestsCount = 0.obs;
  final bnbTodayRevenue = 'TZS 0'.obs;
  final bnbUnitsCount = 0.obs;
  /// Average daily occupancy % for the current week (0–100).
  final bnbOccupancyRate = 0.obs;

  /// Mon–Sun of the current calendar week (same as [RentSmartUtilityDashboardController]).
  static const weeklyDayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  /// BnB income per day (TZS), indexed 0 = Monday … 6 = Sunday.
  final weeklyRevenue = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  /// Daily occupancy % (0–100): occupied unit-nights ÷ available unit-nights.
  final weeklyOccupancyPercent = <double>[0, 0, 0, 0, 0, 0, 0].obs;

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
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  /// Reload metrics when bookings or income change elsewhere.
  static Future<void> refreshIfRegistered({bool quiet = true}) async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard(quiet: quiet);
    }
  }

  Future<void> refreshDashboard() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final incomeRows = await _incomeLocal.getAllNewestFirst();
    final expenseRows = await _expenseLocal.getAllNewestFirst();

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
    final propertyRows = await _propertyLocal.fetchAll(userId: userId);
    final tenants = await _tenantLocal.getAllNewestFirst();
    final portfolio = await RentPortfolioMetricsCalculator.compute(
      properties: propertyRows.toList(),
      tenants: tenants,
      incomeRows: incomeRows,
      now: now,
    );
    _monthlyIncome.value = portfolio.monthlyIncome;
    _occupancyPercent.value = portfolio.occupancyPercent;
    _activeLeases.value = portfolio.activeLeases;
    _totalArrears.value = portfolio.totalArrears;
  }

  Future<void> loadDashboard({bool quiet = false}) async {
    if (!quiet) isLoading.value = true;
    try {
      // if (isBnbWorkspace.value) {
        await _loadBnbOverviewStats();
      // } else {
      //   weeklyRevenue.assignAll(List<double>.filled(7, 0));
      //   weeklyOccupancyPercent.assignAll(List<double>.filled(7, 0));
      // }
      final incomes =
          await _incomeLocal.getAllNewestFirst();
      final expenses =
          await _expenseLocal.getAllNewestFirst();

      logger.d(
        'Dashboard loadDashboard '
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

      totalRevenue.value = Get.find<CurrencyService>().formatBase(revThis.round());
      totalRevenueChange.value = _pctChange(revThis, revLast);
      totalRevenueUp.value = revThis >= revLast;

      final avgDailyThis =
          daysThisMonth > 0 ? revThis / daysThisMonth : 0.0;
      final avgDailyLast =
          daysLastMonth > 0 ? revLast / daysLastMonth : 0.0;
      avgDailyRate.value = Get.find<CurrencyService>().formatBase(avgDailyThis.round());
      avgDailyRateChange.value = _pctChange(avgDailyThis, avgDailyLast);
      avgDailyRateUp.value = avgDailyThis >= avgDailyLast;

      final profitThis = revThis - expThis;
      final profitLast = revLast - expLast;
      netProfit.value = Get.find<CurrencyService>().formatBase(profitThis.round());
      netProfitChange.value = _pctChange(profitThis, profitLast);
      netProfitUp.value = profitThis >= profitLast;

      totalExpenses.value = Get.find<CurrencyService>().formatBase(expThis.round());
      totalExpensesChange.value = _pctChange(expThis, expLast);
      totalExpensesUp.value = expThis >= expLast;

      final avgExpDailyThis =
          daysThisMonth > 0 ? expThis / daysThisMonth : 0.0;
      final avgExpDailyLast =
          daysLastMonth > 0 ? expLast / daysLastMonth : 0.0;
      avgDailyExpense.value =
          Get.find<CurrencyService>().formatBase(avgExpDailyThis.round());
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
      if (!quiet) isLoading.value = false;
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

  Future<void> recordPayment() async {
    final saved = await Get.toNamed(Routes.RECORD_PAYMENT);
    if (saved == true) {
      await loadDashboard();
    }
  }

  Future<void> addExpense() async {
    final saved = await Get.toNamed(Routes.ADD_EXPENSE);
    if (saved == true) {
      await loadDashboard();
    }
  }

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

  Future<void> _loadBnbOverviewStats() async {
    final weekStart = _currentWeekMondayStart();
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};
    var unitsTotal = 0;

    try {
      final res = await _repository.getAllBookings();
      if (BookingApiResponse.isSuccess(res.responseCode)) {
        for (final m in BookingApiResponse.parseBookingsList(res.data)) {
          final item = merge.fromApiMap(m);
          if (item.isCancelled) continue;
          merged[item.bookingKey] = item;
        }
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      await mergePendingBnbBookings(
        merge: merge,
        merged: merged,
        properties: properties,
        loader: _pendingBookingLoader,
      );

      for (final p in properties) {
        unitsTotal += _bnbUnitCountForProperty(p);
      }
      bnbUnitsCount.value = unitsTotal;
    } catch (_) {
      bnbUnitsCount.value = 0;
      unitsTotal = 0;
    }

    final active = merged.values.where(_isActiveBnbBooking).toList();
    bnbBookingsCount.value = active.length;

    final guestKeys = <String>{};
    for (final item in active) {
      final name = item.guestName.trim().toLowerCase();
      if (name.isNotEmpty) guestKeys.add(name);
    }
    bnbGuestsCount.value = guestKeys.length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    var todaySum = 0.0;
    var incomes = <IncomeRecord>[];
    try {
      incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
      for (final r in incomes) {
        final d = r.paidLocalCalendarOrCreated();
        if (!d.isBefore(today) && d.isBefore(tomorrow)) {
          todaySum += r.amountValue;
        }
      }
    } catch (_) {}
    bnbTodayRevenue.value =
        Get.find<CurrencyService>().formatBase(todaySum.round());

    // _assignWeeklyRevenue(incomes, weekStart);
    // _assignWeeklyOccupancy(merged.values, unitsTotal, weekStart);
    final occ = weeklyOccupancyPercent;
    if (occ.isEmpty) {
      bnbOccupancyRate.value = 0;
    } else {
      bnbOccupancyRate.value =
          (occ.fold<double>(0, (a, b) => a + b) / occ.length).round().clamp(0, 100);
    }
  }

  /// Monday 00:00 of the current calendar week (local).
  static DateTime _currentWeekMondayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  static DateTime? _parseCalendarDay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
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
    final p = DateTime.tryParse(t);
    if (p == null) return null;
    return DateTime(p.year, p.month, p.day);
  }

  static bool _isActiveBnbBooking(CheckInItem item) {
    if (item.isInactive) return false;
    final co = DateTime.tryParse(item.checkOutIso.trim());
    if (co != null) {
      final now = DateTime.now();
      final end = DateTime(co.year, co.month, co.day);
      final today = DateTime(now.year, now.month, now.day);
      if (end.isBefore(today)) return false;
    }
    return true;
  }

  static int _bnbUnitCountForProperty(PropertyRecord p) {
    final raw = p.unitsJson.trim();
    if (raw.isNotEmpty && raw != '[]') {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) return decoded.length;
      } catch (_) {}
    }
    if (p.units > 0) return p.units;
    return 1;
  }

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