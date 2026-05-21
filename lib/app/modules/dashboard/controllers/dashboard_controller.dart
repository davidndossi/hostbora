import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/model/community.dart';
import '../../../data/model/user_community.dart';
import '../../../data/repository/app_repository.dart';
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
  final PropertyLocalDataSource _propertyLocal =
      Get.find<PropertyLocalDataSource>();
  final WorkspaceContextService _workspaceContext =
      Get.find<WorkspaceContextService>();
  final AppRepository _repository =
      Get.find<AppRepository>(tag: (AppRepository).toString());
  final PendingBookingsStore _pendingBookingsStore = PendingBookingsStore();

  static final _money = NumberFormat('#,###', 'en_US');

  final isBnbWorkspace = true.obs;
  final bnbBookingsCount = 0.obs;
  final bnbGuestsCount = 0.obs;
  final bnbTodayRevenue = 'TZS 0'.obs;
  final bnbUnitsCount = 0.obs;

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
      final ws = await _workspaceContext.getWorkspaceType();
      isBnbWorkspace.value = ws == 'bnb';
      if (isBnbWorkspace.value) {
        await _loadBnbOverviewStats();
      } else {
        weeklyRevenue.assignAll(List<double>.filled(7, 0));
        weeklyOccupancyPercent.assignAll(List<double>.filled(7, 0));
      }
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

  void openBookings() => Get.toNamed(Routes.ALL_BOOKINGS);

  void openProperties() => Get.toNamed(Routes.MY_PROPERTIES);

  void openTodayRevenue() =>
      Get.toNamed(Routes.RENT_MANAGE_PAYMENTS, arguments: {'ws': 'bnb'});

  Future<void> _loadBnbOverviewStats() async {
    final weekStart = _currentWeekMondayStart();
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};
    var unitsTotal = 0;

    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final item = merge.fromApiMap(Map<String, dynamic>.from(e));
        merged[item.bookingKey] = item;
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      for (final m in _pendingBookingsStore.load()) {
        final listingId = (m['listingId'] ?? '').toString().trim();
        final checkIn = (m['checkIn'] ?? '').toString();
        final checkOut = (m['checkOut'] ?? '').toString();
        if (listingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) {
          continue;
        }
        final property = properties.firstWhereOrNull(
          (p) =>
              p.propertyRef.trim() == listingId ||
              'local_${p.id}' == listingId,
        );
        final propertyLabel = property?.propertyName.trim().isNotEmpty == true
            ? property!.propertyName.trim()
            : (property?.propertyLocation ?? 'Property');
        final localId = 'local_${m['createdAt'] ?? '${listingId}_$checkIn'}';
        merged[localId] = merge.fromPendingMap(
          m,
          propertyLabel: propertyLabel,
          localId: localId,
        );
      }

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
    bnbTodayRevenue.value = 'TZS ${_money.format(todaySum.round())}';

    _assignWeeklyRevenue(incomes, weekStart);
    _assignWeeklyOccupancy(merged.values, unitsTotal, weekStart);
  }

  /// Monday 00:00 of the current calendar week (local).
  static DateTime _currentWeekMondayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  void _assignWeeklyRevenue(List<IncomeRecord> incomes, DateTime weekStart) {
    final totals = List<double>.filled(7, 0);
    for (final r in incomes) {
      final d = r.paidLocalCalendarOrCreated();
      final day = DateTime(d.year, d.month, d.day);
      final diff = day.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) totals[diff] += r.amountValue;
    }
    weeklyRevenue.assignAll(totals);
  }

  /// Occupancy per calendar day: for each Mon–Sun day,
  /// `occupied / totalUnits * 100`, capped at 100.
  ///
  /// - **Available** unit-nights for a day = [totalUnits] (all BnB units).
  /// - **Occupied** unit-nights = count of non-checked-out bookings whose stay
  ///   overlaps that day on half-open `[checkIn, checkOut)` (checkout day excluded).
  /// - Each booking counts as one unit (no per-booking unit count in [CheckInItem]).
  void _assignWeeklyOccupancy(
    Iterable<CheckInItem> bookings,
    int totalUnits,
    DateTime weekStart,
  ) {
    final pct = List<double>.filled(7, 0);
    if (totalUnits <= 0) {
      weeklyOccupancyPercent.assignAll(pct);
      return;
    }
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      var occupied = 0;
      for (final item in bookings) {
        if (_bookingOccupiesCalendarDay(item, day)) occupied++;
      }
      pct[i] = ((occupied / totalUnits) * 100).clamp(0.0, 100.0);
    }
    weeklyOccupancyPercent.assignAll(pct);
  }

  static bool _bookingOccupiesCalendarDay(CheckInItem item, DateTime day) {
    if (item.isInactive) return false;
    final ci = _parseCalendarDay(item.checkInIso);
    final co = _parseCalendarDay(item.checkOutIso);
    if (ci == null || co == null) return false;
    return !day.isBefore(ci) && day.isBefore(co);
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

}