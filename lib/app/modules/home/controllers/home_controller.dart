import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:host_bora/app/core/values/text_styles.dart';

import '../../../core/utils/booking_api_response.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '/app/core/base/base_controller.dart';

class HomeController extends BaseController with GetTickerProviderStateMixin {
  final unreadCount = 0.obs;

  // final PreferenceManager _preferenceManager =
  //     Get.find(tag: (PreferenceManager).toString());
  final WorkspaceContextService _workspaceContext =
      Get.find<WorkspaceContextService>();
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PropertyLocalDataSource _propertyLocal =
      Get.find<PropertyLocalDataSource>();
  final TenantLocalDataSource _bnbTenantLocal =
      Get.find<TenantLocalDataSource>();
  final IncomeLocalDataSource _incomeLocal = Get.find<IncomeLocalDataSource>();
  final PendingBookingsStore _pendingBookingsStore = PendingBookingsStore();
  late final BnbBookingPendingLoader _pendingBookingLoader =
      BnbBookingPendingLoader(
        syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
      );

  late String username;
  late TabController tabController;

  final roles = [].obs;
  final userId = ''.obs;
  final communityId = ''.obs;
  final isAdmin = false.obs;
  final isLeader = false.obs;

  // Timer? _debounce;

  final showList = false.obs;

  final activeBookings = 0.obs;
  final monthlyRevenue = 'TZS 0'.obs;
  final bookingsChange = '+0% from last month'.obs;
  final revenueChange = '+0% from last month'.obs;

  final checkIns = <CheckInItem>[].obs;
  final checkInsToday = <CheckInItem>[].obs;
  final checkOutsToday = <CheckInItem>[].obs;

  /// True only before the first successful [loadHomeData] (skeleton, not full-screen spinner).
  final homeInitialLoading = true.obs;

  /// Pull-to-refresh indicator on BnB home.
  final homeRefreshing = false.obs;

  final homeHasLoaded = false.obs;

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

  final bnbBookingsCount = 0.obs;
  final bnbGuestsCount = 0.obs;
  final bnbTodayRevenue = 'TZS 0'.obs;
  final bnbUnitsCount = 0.obs;
  /// Average daily occupancy % for the current week (0–100).
  final bnbOccupancyRate = 0.obs;

  /// Total units across both BnB and Rent workspaces.
  final totalUnitsCount = 0.obs;
  /// % of rent units currently occupied by an active tenant.
  final rentOccupancyRate = 0.obs;
  /// Number of active rent tenants (lease not yet expired).
  final rentTenantsCount = 0.obs;
  /// % of expected monthly rent that has been collected this month.
  final collectionRate = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _workspaceContext.switchWorkspace('bnb');
    loadHomeData();
  }

  Future<void> loadHomeData({bool refresh = false}) async {
    if (refresh) {
      homeRefreshing.value = true;
    } else if (!homeHasLoaded.value) {
      homeInitialLoading.value = true;
    }
    try {
      await Future.wait([
        _loadOverview(),
        _loadBookingLists(),
        _loadBnbOverviewStats(),
        _loadRentOverviewStats(),
      ]);
    } catch (e) {
      if (e is Exception) {
        showErrorMessage(e.toString());
      }
    } finally {
      homeInitialLoading.value = false;
      homeRefreshing.value = false;
      homeHasLoaded.value = true;
    }
  }

  Future<void> _loadOverview() async {
    var remoteActive = 0;
    var remoteRevenueLabel = 'TZS 0';
    String? remoteBookingsChange;
    try {
      final res = await _repository.getHomeOverview();
      if (res.responseCode == '0' && res.data != null) {
        final d = res.data! as Map<String, dynamic>;
        remoteActive = (d['activeBookings'] as num?)?.toInt() ?? 0;
        remoteRevenueLabel = (d['monthlyRevenue'] as String?) ?? 'TZS 0';
        remoteBookingsChange = (d['bookingsChange'] as String?)?.trim();
      }
    } catch (_) {}

    final pendingMaps = await _pendingBookingLoader.loadAll();
    final localActive = pendingMaps.length;

    final tenantRows = await _bnbTenantLocal
        .getAllForBnbWorkspaceByPropertyRefJoin();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    var localCurrentBookings = 0;
    var localPreviousBookings = 0;
    for (final t in tenantRows) {
      DateTime leaseStart;
      try {
        leaseStart = DateTime.parse(t.leaseStartIso.trim());
      } catch (_) {
        leaseStart = DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
      }
      DateTime leaseEnd;
      try {
        leaseEnd = DateTime.parse(t.leaseEndIso.trim());
      } catch (_) {
        // Open-ended / bad end date: treat as ongoing far into the future.
        leaseEnd = DateTime(now.year + 50, 12, 31);
      }

      if (_leaseOverlapsCalendarMonth(
        leaseStart: leaseStart,
        leaseEnd: leaseEnd,
        monthStart: monthStart,
        nextMonthStart: nextMonthStart,
      )) {
        localCurrentBookings++;
      }
      if (_leaseOverlapsCalendarMonth(
        leaseStart: leaseStart,
        leaseEnd: leaseEnd,
        monthStart: prevMonthStart,
        nextMonthStart: monthStart,
      )) {
        localPreviousBookings++;
      }
    }

    double bnbLocalIncomeThisMonth = 0;
    double bnbLocalIncomePrevMonth = 0;
    try {
      final incomeRows = await _incomeLocal
          .getAllForBnbWorkspaceByPropertyRefJoin();
      for (final r in incomeRows) {
        if (r.workspaceType.trim().toLowerCase() != 'bnb') continue;
        final parsed = DateTime.tryParse(r.datePaidIso.trim());
        if (parsed == null) continue;
        final d = DateTime(parsed.year, parsed.month, parsed.day);
        if (!d.isBefore(monthStart) && d.isBefore(nextMonthStart)) {
          bnbLocalIncomeThisMonth += r.amountValue;
        } else if (!d.isBefore(prevMonthStart) && d.isBefore(monthStart)) {
          bnbLocalIncomePrevMonth += r.amountValue;
        }
      }
    } catch (_) {}

    final combinedMonthly = bnbLocalIncomeThisMonth;
    final combinedPrev = bnbLocalIncomePrevMonth;

    activeBookings.value = localActive > remoteActive
        ? localActive
        : remoteActive;
    if (combinedMonthly > 0) {
      monthlyRevenue.value = Get.find<CurrencyService>().formatBase(
        combinedMonthly.round(),
      );
    } else {
      monthlyRevenue.value = remoteRevenueLabel;
    }
    bookingsChange.value =
        (remoteBookingsChange != null && remoteBookingsChange.isNotEmpty)
        ? remoteBookingsChange
        : _formatMoMPercent(
            localCurrentBookings.toDouble(),
            localPreviousBookings.toDouble(),
          );
    revenueChange.value = _formatMoMPercent(combinedMonthly, combinedPrev);
  }

  /// Monday 00:00 of the current calendar week (local).
  static DateTime _currentWeekMondayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
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

    _assignWeeklyRevenue(incomes, weekStart);
    _assignWeeklyOccupancy(merged.values, unitsTotal, weekStart);
    final occ = weeklyOccupancyPercent;
    if (occ.isEmpty) {
      bnbOccupancyRate.value = 0;
    } else {
      bnbOccupancyRate.value =
          (occ.fold<double>(0, (a, b) => a + b) / occ.length).round().clamp(0, 100);
    }
  }

  Future<void> _loadRentOverviewStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);

      // ── Units: count across both workspaces ──────────────────────────────
      final rentProperties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'rent',
      );
      var rentUnits = 0;
      for (final p in rentProperties) {
        rentUnits += _bnbUnitCountForProperty(p);
      }
      // Total = rent + BnB (already counted in _loadBnbOverviewStats)
      // We re-count BnB here to avoid a race condition with the parallel call.
      final bnbProperties = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      var bnbUnits = 0;
      for (final p in bnbProperties) {
        bnbUnits += _bnbUnitCountForProperty(p);
      }
      totalUnitsCount.value = rentUnits + bnbUnits;

      // ── Rent tenants & occupancy ─────────────────────────────────────────
      final allRentTenants = await _bnbTenantLocal
          .getAllNewestFirstByWorkspace('rent');
      final activeTenants = allRentTenants.where((t) {
        final raw = t.leaseEndIso.trim();
        if (raw.isEmpty) return true; // open-ended
        final end = DateTime.tryParse(raw);
        if (end == null) return true;
        return !DateTime(end.year, end.month, end.day).isBefore(today);
      }).toList();

      rentTenantsCount.value = activeTenants.length;

      // Occupancy: distinct occupied unit slots / total rent units
      if (rentUnits > 0) {
        final occupiedUnitIds = <String>{};
        for (final t in activeTenants) {
          final uid = t.apartmentUnitId.trim();
          if (uid.isNotEmpty) {
            occupiedUnitIds.add('${t.propertyRef}::$uid');
          } else {
            // Tenant without a unit ID still occupies one slot
            occupiedUnitIds.add('${t.propertyRef}::tenant_${t.id}');
          }
        }
        rentOccupancyRate.value =
            ((occupiedUnitIds.length / rentUnits) * 100).round().clamp(0, 100);
      } else {
        rentOccupancyRate.value = 0;
      }

      // ── Collection rate ──────────────────────────────────────────────────
      // Expected = sum of active tenants' rent amounts (stored as monthly-ish)
      var expectedIncome = 0.0;
      for (final t in activeTenants) {
        expectedIncome += t.rentAmountValue;
      }

      // Collected = rent income recorded this calendar month
      var collectedIncome = 0.0;
      try {
        final rentIncomes = await _incomeLocal.getAllNewestFirst(
          workspaceType: 'rent',
        );
        for (final r in rentIncomes) {
          final parsed = DateTime.tryParse(r.datePaidIso.trim());
          if (parsed == null) continue;
          final d = DateTime(parsed.year, parsed.month, parsed.day);
          if (!d.isBefore(monthStart) && d.isBefore(nextMonthStart)) {
            collectedIncome += r.amountValue;
          }
        }
      } catch (_) {}

      if (expectedIncome > 0) {
        collectionRate.value =
            ((collectedIncome / expectedIncome) * 100).round().clamp(0, 999);
      } else {
        collectionRate.value = 0;
      }
    } catch (_) {
      totalUnitsCount.value = 0;
      rentOccupancyRate.value = 0;
      rentTenantsCount.value = 0;
      collectionRate.value = 0;
    }
  }

  /// True when [leaseStart]–[leaseEnd] overlaps half-open calendar month
  /// [monthStart, nextMonthStart) using date-only boundaries (avoids UTC drift).
  static bool _leaseOverlapsCalendarMonth({
    required DateTime leaseStart,
    required DateTime leaseEnd,
    required DateTime monthStart,
    required DateTime nextMonthStart,
  }) {
    final ls = DateTime(leaseStart.year, leaseStart.month, leaseStart.day);
    final le = DateTime(leaseEnd.year, leaseEnd.month, leaseEnd.day);
    final ws = DateTime(monthStart.year, monthStart.month, monthStart.day);
    final we = DateTime(
      nextMonthStart.year,
      nextMonthStart.month,
      nextMonthStart.day,
    );
    return ls.isBefore(we) && le.isAfter(ws);
  }

  String _formatMoMPercent(double current, double previous) {
    if (previous.abs() < 0.0001) {
      if (current.abs() < 0.0001) return '+0% from last month';
      return '+100% from last month';
    }
    final pct = ((current - previous) / previous.abs()) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}% from last month';
  }

  /// Merges API upcoming bookings + local pending (BnB), then derives today /
  /// upcoming lists using local calendar date parts (same day geometry as
  /// occupancy: checkout day is a departure day, not a stay night).
  Future<void> _loadBookingLists() async {
    final all = await loadMergedActiveBnbBookings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final inToday = <CheckInItem>[];
    final outToday = <CheckInItem>[];
    final upcoming = <CheckInItem>[];

    for (final item in all) {
      if (item.isInactive) continue;
      final ci = _parseCalendarDay(item.checkInIso);
      final co = _parseCalendarDay(item.checkOutIso);
      if (ci != null && _dateOnly(ci) == today) {
        inToday.add(item);
      }
      if (co != null && _dateOnly(co) == today) {
        outToday.add(item);
      }
      if (ci != null && !ci.isBefore(today)) {
        upcoming.add(item);
      }
    }

    int sortByCheckIn(CheckInItem a, CheckInItem b) {
      final da = _parseCalendarDay(a.checkInIso);
      final db = _parseCalendarDay(b.checkInIso);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.guestName.compareTo(b.guestName);
    }

    int sortByCheckOut(CheckInItem a, CheckInItem b) {
      final da = _parseCalendarDay(a.checkOutIso);
      final db = _parseCalendarDay(b.checkOutIso);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.guestName.compareTo(b.guestName);
    }

    inToday.sort(sortByCheckIn);
    outToday.sort(sortByCheckOut);
    upcoming.sort(sortByCheckIn);

    checkInsToday.assignAll(inToday);
    checkOutsToday.assignAll(outToday);
    checkIns.assignAll(upcoming);
  }

  /// Shared merge path for home lists (API + pending). Excludes inactive rows.
  Future<List<CheckInItem>> loadMergedActiveBnbBookings() async {
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};

    try {
      final res = await _repository.getUpcomingBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final item = merge.fromApiMap(Map<String, dynamic>.from(e));
        if (item.isInactive) continue;
        merged[item.bookingKey] = item;
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
    } catch (_) {}

    return merged.values.toList();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Same date-only parsing as host dashboard / reports occupancy geometry.
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

  void viewTrends() => Get.toNamed(Routes.FINANCIAL_OVERVIEW);

  void seeAllCheckIns() => Get.toNamed(Routes.ALL_BOOKINGS);

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void properties() => Get.toNamed(Routes.MY_PROPERTIES);

  void tenants() => Get.toNamed(
    Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
    arguments: {'ws': 'bnb'},
  );

  void sendSmsWhatsapp() =>
      Get.toNamed(Routes.SEND_SMS, arguments: const {'workspace': 'bnb'});

  void whatsappTemplates() =>
      Get.toNamed(Routes.RENT_WHATSAPP_TEMPLATE_BUILDER);

  Future<void> addNewBooking() async {
    await _guardPropertyBeforeAction(
      onProceed: () async {
        final saved = await Get.toNamed(Routes.ADD_NEW_BOOKING);
        if (saved == true) {
          await _refreshAfterBookingChange();
        }
      },
    );
  }

  Future<void> _refreshAfterBookingChange() async {
    await loadHomeData();
    await DashboardController.refreshIfRegistered();
    await HostCalendarController.refreshIfRegistered();
  }

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void tasks() => Get.toNamed(Routes.MAINTENANCE_TASKS);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  Future<void> reports() async {
    await Get.toNamed(Routes.REPORTS_HUB);
  }

  void designStudio() => Get.toNamed(Routes.INTERIOR_DESIGN_STUDIO);

  void designMoodboards() => Get.toNamed(Routes.DESIGN_MOODBOARDS);

  void rentHub() => Get.toNamed(Routes.RENT_HUB);

  void aiManager() => Get.toNamed(Routes.AI_MANAGER);

  void openBookings() => Get.toNamed(Routes.ALL_BOOKINGS);

  void openProperties() => Get.toNamed(Routes.MY_PROPERTIES);

  void aiInsights() =>
      Get.toNamed(Routes.AI_INSIGHTS, arguments: const {'source': 'insights'});

  void aiAutomations() => Get.toNamed(
    Routes.AI_AUTOMATIONS,
    arguments: const {'source': 'automations'},
  );

  void documents() => Get.toNamed(Routes.PROPERTY_VAULT);

  void openTodayRevenue() =>
      Get.toNamed(Routes.RENT_MANAGE_PAYMENTS, arguments: {'ws': 'bnb'});

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

  static bool _bookingOccupiesCalendarDay(CheckInItem item, DateTime day) {
    if (item.isInactive) return false;
    final ci = _parseCalendarDay(item.checkInIso);
    final co = _parseCalendarDay(item.checkOutIso);
    if (ci == null || co == null) return false;
    return !day.isBefore(ci) && day.isBefore(co);
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

  Future<void> addExpense() async {
    await _guardPropertyBeforeAction(
      onProceed: () async {
        final saved = await Get.toNamed(Routes.ADD_EXPENSE);
        if (saved == true) {
          await _refreshBnbFinancialSurfaces();
        }
      },
    );
  }

  Future<void> addPayment() async {
    await _guardPropertyBeforeAction(
      onProceed: () async {
        final saved = await Get.toNamed(Routes.RECORD_PAYMENT);
        if (saved == true) {
          await _refreshBnbFinancialSurfaces();
        }
      },
    );
  }

  /// Reloads home metrics and the main-shell dashboard after local income/expense writes.
  Future<void> _refreshBnbFinancialSurfaces() async {
    await _loadOverview();
    await DashboardController.refreshIfRegistered();
  }

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) {
    Get.toNamed(Routes.BOOKING_DETAILS, arguments: item)?.then((
      refreshed,
    ) async {
      if (refreshed == true) {
        await _loadBookingLists();
        await DashboardController.refreshIfRegistered();
        await HostCalendarController.refreshIfRegistered();
      }
    });
  }

  Future<void> _guardPropertyBeforeAction({
    required FutureOr<void> Function() onProceed,
  }) async {
    final hasProperty = await _hasAtLeastOneProperty();
    if (hasProperty) {
      await onProceed();
      return;
    }
    final goToAddListing = await _showAddPropertyRequiredDialog();
    if (goToAddListing == true) {
      await Get.toNamed(Routes.ADD_LISTING);
    }
  }

  Future<bool> _hasAtLeastOneProperty() async {
    try {
      final res = await _repository.getMyListings();
      if (res.responseCode == '0' && res.data != null) {
        final data = res.data;
        if (data is List && data.isNotEmpty) return true;
        if (data is Map && data['content'] is List) {
          if ((data['content'] as List).isNotEmpty) return true;
        }
        if (data is Map && data['listings'] is List) {
          if ((data['listings'] as List).isNotEmpty) return true;
        }
      }
      final localRows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      return localRows.isNotEmpty;
    } catch (_) {
      final localRows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: 'bnb',
      );
      return localRows.isNotEmpty;
    }
  }

  Future<bool?> _showAddPropertyRequiredDialog() {
    final isSw = Get.locale?.languageCode == 'sw';
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(isSw ? 'Ongeza Mjengo Kwanza' : 'Add Property First'),
        content: Text(
          isSw
              ? 'Huwezi kuendelea bila mijengo. Tafadhali ongeza mjengo kwanza.'
              : 'You need at least one property before continuing. Please add a listing first.',
          style: blackText16,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              isSw ? 'Ghairi' : 'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              isSw ? 'Ongeza Mali' : 'Add Listing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> refreshIfRegistered() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHomeData(refresh: true);
    }
  }

  Future<void> retryBookingSync(CheckInItem item) async {
    final queueId = item.syncQueueId;
    if (queueId == null) return;
    final queue = Get.find<OfflineSyncQueueLocalDataSource>();
    final worker = Get.find<OfflineSyncWorkerService>();
    await queue.retryItem(queueId);
    await worker.runNow(maxItems: 20);
    await loadHomeData(refresh: true);
  }
}
