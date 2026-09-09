import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/service/launch_prompt_gate.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../core/utils/bnb_property_listing.dart';
import '../../../core/utils/getx_instance_probe.dart';
import '../../../core/utils/property_unit_count.dart';
import '../../../core/values/text_styles.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_overrides_store.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/deleted_properties_store.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../main/model/menu_code.dart';
import '../../main/widgets/nav_tab_spotlight_overlay.dart';
import '../widgets/quick_actions_dialog.dart';
import '/app/core/base/base_controller.dart';

/// Progressive disclosure stages for Home.
enum HomeExperienceStage { noProperties, firstWeek, established }

class HomeController extends BaseController with GetTickerProviderStateMixin {
  final unreadCount = 0.obs;

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PropertyLocalDataSource _propertyLocal =
      Get.find<PropertyLocalDataSource>();
  final TenantLocalDataSource _bnbTenantLocal =
      Get.find<TenantLocalDataSource>();
  final IncomeLocalDataSource _incomeLocal = Get.find<IncomeLocalDataSource>();
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal =
      Get.find<RentScheduledMaintenanceLocalDataSource>();
  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );
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

  final showList = false.obs;

  final activeBookings = 0.obs;
  final monthlyRevenue = RxString(CurrencyService.zeroLabel());
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

  /// True once we know the account has at least one property. Defaults to
  /// true so returning users never see an empty-state flash while this
  /// resolves; only flips to false after a real zero-property check.
  final hasAnyProperty = true.obs;

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
  final bnbTodayRevenue = RxString(CurrencyService.zeroLabel());
  final bnbUnitsCount = 0.obs;
  /// Average daily occupancy % for the current week (0–100).
  final bnbOccupancyRate = 0.obs;

  /// Distinct properties (unique [propertyRef]) across BnB + Rent.
  final totalPropertiesCount = 0.obs;

  /// Total rentable units across both BnB and Rent (sum of units per property).
  final totalUnitsCount = 0.obs;
  /// % of rent units currently occupied by an active tenant.
  final rentOccupancyRate = 0.obs;
  /// Number of active rent tenants (lease not yet expired).
  final rentTenantsCount = 0.obs;
  /// % of expected monthly rent that has been collected this month.
  final collectionRate = 0.obs;

  /// Expected income for the current calendar month (formatted, base currency).
  final expectedIncomeLabel = RxString(CurrencyService.zeroLabel());

  /// Collected income for the current calendar month (formatted, base currency).
  final collectedIncomeLabel = RxString(CurrencyService.zeroLabel());

  /// Newest income rows (unfiltered); use [visibleRecentPayments] for UI.
  final recentPayments = <IncomeRecord>[].obs;

  /// Maintenance scheduled from today through the next 7 days.
  final upcomingMaintenance = <RentScheduledMaintenanceRecord>[].obs;

  /// Home workspace chip: `all` | `bnb` | `rent`.
  final homeWorkspaceFilter = 'all'.obs;

  /// Derived from the host's properties: `bnb` | `rent` | `both`.
  /// Single-mode portfolios lock Home to that role (no mode chips).
  final homePortfolioRole = 'bnb'.obs;

  /// Which Today alert's guest list is expanded (`checkin` / `checkout` / `upcoming`).
  final todayExpandedKey = RxnString();

  /// Progressive Home stage: empty → first week → established.
  final homeExperienceStage = HomeExperienceStage.noProperties.obs;

  bool get isFirstWeekHome =>
      homeExperienceStage.value == HomeExperienceStage.firstWeek;

  bool get isEstablishedHome =>
      homeExperienceStage.value == HomeExperienceStage.established;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initHomeWorkspaceFilter());
    loadHomeData();
  }

  Future<void> _initHomeWorkspaceFilter() async {
    try {
      final saved = await _preferenceManager.getString(
        PreferenceManager.keyHomeWorkspaceFilter,
        defaultValue: '',
      );
      if (saved == 'all' || saved == 'bnb' || saved == 'rent') {
        homeWorkspaceFilter.value = saved;
        return;
      }
      // Default to the user's preferred workspace (not "all") to reduce noise.
      if (Get.isRegistered<WorkspaceContextService>()) {
        final ws = await Get.find<WorkspaceContextService>().getWorkspaceType();
        homeWorkspaceFilter.value = ws == 'rent' ? 'rent' : 'bnb';
      }
    } catch (_) {}
  }

  Future<void> setHomeWorkspaceFilter(String value) async {
    // Single-mode portfolios stay locked to their role.
    final role = homePortfolioRole.value;
    if (role == 'bnb' || role == 'rent') {
      homeWorkspaceFilter.value = role;
      return;
    }
    final next = value == 'bnb' || value == 'rent' ? value : 'all';
    homeWorkspaceFilter.value = next;
    todayExpandedKey.value = null;
    try {
      await _preferenceManager.setString(
        PreferenceManager.keyHomeWorkspaceFilter,
        next,
      );
    } catch (_) {}
  }

  bool get showWorkspaceFilterChips => homePortfolioRole.value == 'both';

  bool get showBnbHomeContent {
    final role = homePortfolioRole.value;
    if (role == 'bnb') return true;
    if (role == 'rent') return false;
    final f = homeWorkspaceFilter.value;
    return f == 'all' || f == 'bnb';
  }

  bool get showRentHomeContent {
    final role = homePortfolioRole.value;
    if (role == 'rent') return true;
    if (role == 'bnb') return false;
    final f = homeWorkspaceFilter.value;
    return f == 'all' || f == 'rent';
  }

  /// Up to 5 recent payments for the current home workspace filter.
  List<IncomeRecord> get visibleRecentPayments {
    final showBnb = showBnbHomeContent;
    final showRent = showRentHomeContent;
    Iterable<IncomeRecord> rows = recentPayments;
    if (showBnb && !showRent) {
      rows = rows.where((r) => r.workspaceType.trim().toLowerCase() == 'bnb');
    } else if (showRent && !showBnb) {
      rows = rows.where((r) => r.workspaceType.trim().toLowerCase() != 'bnb');
    }
    return rows.take(5).toList();
  }

  /// Upcoming maintenance visible for the current workspace filter.
  List<RentScheduledMaintenanceRecord> get visibleUpcomingMaintenance {
    final showBnb = showBnbHomeContent;
    final showRent = showRentHomeContent;
    Iterable<RentScheduledMaintenanceRecord> rows = upcomingMaintenance;
    if (showBnb && !showRent) {
      rows = rows.where((r) => r.workspaceType.trim().toLowerCase() == 'bnb');
    } else if (showRent && !showBnb) {
      rows = rows.where((r) => r.workspaceType.trim().toLowerCase() != 'bnb');
    }
    return rows.toList();
  }

  /// Opens the single Create menu. Never auto-shown.
  Future<void> openCreateMenu() async {
    if (!hasAnyProperty.value) {
      await addListing();
      return;
    }
    try {
      await showCreateMenu(
        onDataChanged: () => loadHomeData(refresh: true),
        portfolioRole: homePortfolioRole.value,
      );
    } catch (_) {}
  }

  /// People list — always [Routes.ALL_TENANTS] (BnB guests + rent tenants).
  void openPeople() => Get.toNamed(Routes.ALL_TENANTS);

  /// Switches main shell to the Properties tab (preferred over a stacked route).
  void openPropertiesTab() {
    try {
      Get.find<MainController>().onMenuSelected(MenuCode.PROPERTIES);
    } catch (_) {
      Get.toNamed(Routes.MY_PROPERTIES);
    }
  }

  /// Role-aware first action for first-week Home.
  Future<void> openPrimaryCreateAction() async {
    if (showBnbHomeContent && !showRentHomeContent) {
      await addNewBooking();
      return;
    }
    if (showRentHomeContent && !showBnbHomeContent) {
      await Get.toNamed(Routes.ADD_NEW_TENANT);
      return;
    }
    await openCreateMenu();
  }

  void toggleTodayDetail(String key) {
    todayExpandedKey.value =
        todayExpandedKey.value == key ? null : key;
  }

  Future<void>? _loadHomeInFlight;
  DateTime? _lastHomeLoadAt;

  /// Loads home data.
  ///
  /// [refresh] shows the pull-to-refresh indicator when already loaded.
  /// [force] bypasses the 2s refresh throttle and waits out any in-flight load
  /// then reloads — required after cancel/checkout so Today lists drop inactive
  /// bookings instead of keeping a stale "Confirmed" card.
  Future<void> loadHomeData({bool refresh = false, bool force = false}) async {
    // Coalesce overlapping loads (sync drain + tab reselect + onInit).
    if (_loadHomeInFlight != null) {
      if (!force) return _loadHomeInFlight!;
      await _loadHomeInFlight!;
    }
    if (!force &&
        refresh &&
        homeHasLoaded.value &&
        _lastHomeLoadAt != null &&
        DateTime.now().difference(_lastHomeLoadAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    if (refresh) {
      homeRefreshing.value = true;
    } else if (!homeHasLoaded.value) {
      homeInitialLoading.value = true;
    }

    final future = _runLoadHomeData(refresh: refresh);
    _loadHomeInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_loadHomeInFlight, future)) {
        _loadHomeInFlight = null;
      }
    }
  }

  Future<void> _runLoadHomeData({required bool refresh}) async {
    try {
      await Future.wait([
        _loadOverview(),
        _loadBookingLists(),
        _loadBnbOverviewStats(),
        _loadRentOverviewStats(),
        _loadRecentPayments(),
        _loadUpcomingMaintenance(),
        _loadPropertyPresence(),
        _loadPortfolioRole(),
      ]);
      await _resolveExperienceStage();
      _lastHomeLoadAt = DateTime.now();
    } catch (e) {
      if (e is Exception) {
        showErrorMessage(e.toString());
      }
    } finally {
      homeInitialLoading.value = false;
      homeRefreshing.value = false;
      homeHasLoaded.value = true;
      if (!refresh) {
        unawaited(_maybeShowPropertiesTabSpotlight());
      }
    }
  }

  Future<void> _resolveExperienceStage() async {
    if (!hasAnyProperty.value) {
      homeExperienceStage.value = HomeExperienceStage.noProperties;
      return;
    }
    try {
      var firstMs = await _preferenceManager.getInt(
        PreferenceManager.keyFirstPropertyAtMs,
        defaultValue: 0,
      );
      if (firstMs <= 0) {
        firstMs = DateTime.now().millisecondsSinceEpoch;
        await _preferenceManager.setInt(
          PreferenceManager.keyFirstPropertyAtMs,
          firstMs,
        );
      }
      final days = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(firstMs))
          .inDays;
      homeExperienceStage.value = days < 7
          ? HomeExperienceStage.firstWeek
          : HomeExperienceStage.established;
    } catch (_) {
      homeExperienceStage.value = HomeExperienceStage.established;
    }
  }

  /// Infers whether this host runs BnB, Rent, or both from property modes.
  Future<void> _loadPortfolioRole() async {
    try {
      final bnbRows = await _propertyLocal.getAllByWorkspace(
        userId: '',
        workspaceType: 'bnb',
      );
      final rentRows = await _propertyLocal.getAllByWorkspace(
        userId: '',
        workspaceType: 'rent',
      );
      var hasBnb = false;
      var hasRent = false;
      for (final r in [...bnbRows, ...rentRows]) {
        final mode = r.workspaceType.trim().toLowerCase();
        if (mode == 'bnb' || mode == 'both') hasBnb = true;
        if (mode == 'rent' || mode == 'both') hasRent = true;
      }
      // A property tagged only as the queried workspace still counts.
      if (bnbRows.isNotEmpty) hasBnb = true;
      if (rentRows.isNotEmpty) hasRent = true;

      final role = hasBnb && hasRent
          ? 'both'
          : hasRent && !hasBnb
              ? 'rent'
              : 'bnb';
      homePortfolioRole.value = role;
      if (role == 'bnb' || role == 'rent') {
        homeWorkspaceFilter.value = role;
      }
    } catch (_) {
      // Keep previous role on failure.
    }
  }

  /// Polls until Home is idle (on the MAIN route, no dialog/bottom-sheet
  /// already showing) or [maxWait] elapses, whichever comes first.
  Future<bool> _waitUntilHomeIsIdle({
    required Duration maxWait,
    Duration pollEvery = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(maxWait);
    while (true) {
      final isFree = Get.currentRoute == Routes.MAIN &&
          !(Get.isDialogOpen ?? false) &&
          !(Get.isBottomSheetOpen ?? false);
      if (isFree) return true;
      if (DateTime.now().isAfter(deadline)) return false;
      await Future.delayed(pollEvery);
    }
  }

  Future<void> _loadPropertyPresence() async {
    hasAnyProperty.value = await _hasAtLeastOneProperty();
  }

  /// One-time nudge for brand-new (zero-property) accounts: dims the screen
  /// and spotlights the "Properties" bottom-nav tab so first-time users know
  /// exactly where to go to add their first listing.
  Future<void> _maybeShowPropertiesTabSpotlight() async {
    if (hasAnyProperty.value) return;
    bool alreadySeen;
    try {
      alreadySeen = await _preferenceManager.getBool(
        PreferenceManager.keyHasSeenPropertiesTabSpotlight,
      );
    } catch (_) {
      return;
    }
    if (alreadySeen) return;

    await Future.delayed(const Duration(milliseconds: 3200));
    if (hasAnyProperty.value) return;

    final isIdle = await _waitUntilHomeIsIdle(
      maxWait: const Duration(seconds: 8),
    );
    if (!isIdle) return;
    if (hasAnyProperty.value) return;
    if (Get.isRegistered<LaunchPromptGate>() &&
        !Get.find<LaunchPromptGate>().tryClaimSoftPrompt()) {
      return;
    }

    try {
      await _preferenceManager.setBool(
        PreferenceManager.keyHasSeenPropertiesTabSpotlight,
        true,
      );
      await showPropertiesTabSpotlight(isSw: Get.locale?.languageCode == 'sw');
    } catch (_) {
      // Best-effort guidance only — never let this break Home.
    }
  }

  Future<void> _loadOverview() async {
    var remoteActive = 0;
    var remoteRevenueLabel = CurrencyService.zeroLabel();
    String? remoteBookingsChange;
    try {
      final res = await _repository.getHomeOverview();
      if (res.responseCode == '0' && res.data != null) {
        final d = res.data! as Map<String, dynamic>;
        remoteActive = (d['activeBookings'] as num?)?.toInt() ?? 0;
        remoteRevenueLabel = (d['monthlyRevenue'] as String?) ??
            CurrencyService.zeroLabel();
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

  /// Same property set My Properties uses: visible to the logged-in user,
  /// both workspaces, deduped by propertyRef, excluding deleted refs.
  Future<Map<String, PropertyRecord>> _visiblePropertiesByRef() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final deleted = DeletedPropertiesStore().load();
    final byRef = <String, PropertyRecord>{};
    for (final workspace in const ['bnb', 'rent']) {
      final rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: workspace,
      );
      for (final p in rows) {
        final key = p.propertyRef.trim().isNotEmpty
            ? p.propertyRef.trim()
            : 'local_${p.id}';
        if (deleted.contains(key) || deleted.contains('local_${p.id}')) {
          continue;
        }
        final existing = byRef[key];
        if (existing == null) {
          byRef[key] = p;
          continue;
        }
        // Prefer the row with the richer unit definition when the same
        // property exists in both BnB and Rent workspace rows.
        if (PropertyUnitCount.of(p) > PropertyUnitCount.of(existing)) {
          byRef[key] = p;
        }
      }
    }
    return byRef;
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
      final properties = await _propertyLocal.getAllByWorkspace(
        userId: '',
        workspaceType: 'bnb',
      );
      await mergePendingBnbBookings(
        merge: merge,
        merged: merged,
        properties: properties,
        loader: _pendingBookingLoader,
      );

      // One property = one unit, keyed by propertyRef.
      final seenBnbRefs = <String>{};
      for (final p in properties) {
        final key = p.propertyRef.trim().isNotEmpty
            ? p.propertyRef.trim()
            : 'local_${p.id}';
        seenBnbRefs.add(key);
      }
      unitsTotal = seenBnbRefs.length;
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

    // Occupancy denominator = total rentable units across visible properties.
    final allTenants = await _bnbTenantLocal.getAllNewestFirst();
    var allUnitsTotal = 0;
    try {
      final byRef = await _visiblePropertiesByRef();
      allUnitsTotal = byRef.values.fold<int>(
        0,
        (sum, p) => sum + PropertyUnitCount.of(p),
      );
    } catch (_) {}
    _assignWeeklyOccupancy(allTenants, allUnitsTotal, weekStart);

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

      // Match My Properties: visible rows for this user, deduped by propertyRef.
      final byRef = await _visiblePropertiesByRef();

      if (kDebugMode) {
        debugPrint('[Units] Visible properties: ${byRef.length}');
        for (final e in byRef.entries) {
          final p = e.value;
          debugPrint(
            '[Units]  ref="${e.key}" name="${p.propertyName}" '
            'workspace="${p.workspaceType}" unitsCol=${p.units} '
            'unitCount=${PropertyUnitCount.of(p)}',
          );
        }
      }

      final rentRefs = <String>{};
      for (final e in byRef.entries) {
        final ws = e.value.workspaceType.trim().toLowerCase();
        if (ws == 'rent' || ws == 'both' || ws.isEmpty) {
          rentRefs.add(e.key);
        }
      }

      totalPropertiesCount.value = byRef.length;
      totalUnitsCount.value = byRef.values.fold<int>(
        0,
        (sum, p) => sum + PropertyUnitCount.of(p),
      );
      final rentUnitsTotal = byRef.entries
          .where((e) => rentRefs.contains(e.key))
          .fold<int>(0, (sum, e) => sum + PropertyUnitCount.of(e.value));

      // ── All active tenants (rent + BnB guests) ───────────────────────────
      final allTenants = await _bnbTenantLocal.getAllNewestFirst();
      final activeTenants = allTenants.where((t) {
        final raw = t.leaseEndIso.trim();
        if (raw.isEmpty) return true; // open-ended
        final end = DateTime.tryParse(raw);
        if (end == null) return true;
        return !DateTime(end.year, end.month, end.day).isBefore(today);
      }).toList();

      // Count covers both rent tenants and BnB guests.
      rentTenantsCount.value = activeTenants.length;

      // Occupancy: distinct occupied unit slots / total rent units
      if (rentUnitsTotal > 0) {
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
            ((occupiedUnitIds.length / rentUnitsTotal) * 100)
                .round()
                .clamp(0, 100);
      } else {
        rentOccupancyRate.value = 0;
      }

      // ── Collection rate ──────────────────────────────────────────────────
      // Expected = sum of each active tenant's income attributable to this
      // calendar month, accounting for per-night (BnB) vs monthly (rent) rates.
      var expectedIncome = 0.0;
      final monthDays = nextMonthStart.difference(monthStart).inDays;
      final cs = Get.find<CurrencyService>();
      final baseCurrency = cs.baseCurrency.value.trim().toUpperCase();
      for (final t in activeTenants) {
        var tenantMonthly = _expectedMonthlyAmount(
          t,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
          monthDays: monthDays,
        );
        // Convert contract currency to base if different.
        final tenantCurrency = t.rentCurrency.trim().toUpperCase();
        if (tenantCurrency.isNotEmpty && tenantCurrency != baseCurrency) {
          final rate = cs.sellingRateFor(tenantCurrency) ?? 0;
          if (rate > 0) tenantMonthly *= rate;
        }
        expectedIncome += tenantMonthly;
      }

      // Collected = income recorded this calendar month
      var collectedIncome = 0.0;
      try {
        final rentIncomes = await _incomeLocal.getAllNewestFirst();
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
      expectedIncomeLabel.value = cs.formatBaseShort(expectedIncome);
      collectedIncomeLabel.value = cs.formatBaseShort(collectedIncome);
    } catch (_) {
      totalPropertiesCount.value = 0;
      totalUnitsCount.value = 0;
      rentOccupancyRate.value = 0;
      rentTenantsCount.value = 0;
      collectionRate.value = 0;
      expectedIncomeLabel.value = CurrencyService.zeroLabel();
      collectedIncomeLabel.value = CurrencyService.zeroLabel();
    }
  }

  Future<void> _loadRecentPayments() async {
    try {
      final rows = await _incomeLocal.getAllNewestFirst();
      recentPayments.assignAll(rows.take(20).toList());
    } catch (_) {
      recentPayments.clear();
    }
  }

  Future<void> _loadUpcomingMaintenance() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = today.add(const Duration(days: 7));
      final rows = await _maintenanceLocal.getAllNewestFirst();
      final upcoming = <RentScheduledMaintenanceRecord>[];
      for (final r in rows) {
        final parsed = DateTime.tryParse(r.scheduledDateIso.trim());
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(today) || day.isAfter(end)) continue;
        upcoming.add(r);
      }
      upcoming.sort(
        (a, b) => a.scheduledDateIso.compareTo(b.scheduledDateIso),
      );
      upcomingMaintenance.assignAll(upcoming);
    } catch (_) {
      upcomingMaintenance.clear();
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

  /// Returns the portion of [t]'s income that is expected within the calendar
  /// month [monthStart, nextMonthStart).
  ///
  /// - BnB / per-night tenants: rate × nights of their stay that fall in month.
  /// - Monthly tenants: full [rentAmountValue] if their lease covers any part of
  ///   the month.
  /// - Weekly tenants: (rate / 7) × days of overlap (≈ weekly pro-rata).
  /// - Yearly tenants: (rate / 365) × days of overlap.
  static double _expectedMonthlyAmount(
    TenantRecord t, {
    required DateTime monthStart,
    required DateTime nextMonthStart,
    required int monthDays,
  }) {
    if (t.rentAmountValue <= 0) return 0;

    final freq = t.rentFrequency.trim().toLowerCase();
    final isPerNight = freq.contains('night');
    final isWeekly = freq.contains('week');
    final isYearly = freq.contains('year') || freq.contains('annual');

    // For per-night & weekly/yearly, compute overlap days with current month.
    if (isPerNight || isWeekly || isYearly) {
      final start = _parseCalendarDay(t.leaseStartIso.trim());
      if (start == null) return 0;

      // Clamp stay start to month start.
      final overlapStart =
          start.isBefore(monthStart) ? monthStart : start;

      // Lease end: open-ended leases run to end of month.
      DateTime overlapEnd;
      final endRaw = t.leaseEndIso.trim();
      if (endRaw.isEmpty) {
        overlapEnd = nextMonthStart;
      } else {
        final end = _parseCalendarDay(endRaw);
        if (end == null) {
          overlapEnd = nextMonthStart;
        } else {
          // End is inclusive: add 1 day so "before nextMonthStart" works.
          final endPlusOne = end.add(const Duration(days: 1));
          overlapEnd =
              endPlusOne.isBefore(nextMonthStart) ? endPlusOne : nextMonthStart;
        }
      }

      final overlapDays = overlapEnd.difference(overlapStart).inDays;
      if (overlapDays <= 0) return 0;

      if (isPerNight) return t.rentAmountValue * overlapDays;
      if (isWeekly) return (t.rentAmountValue / 7) * overlapDays;
      // yearly
      return (t.rentAmountValue / 365) * overlapDays;
    }

    // Monthly (default): count the full amount if lease overlaps this month.
    final start = _parseCalendarDay(t.leaseStartIso.trim());
    if (start == null) return t.rentAmountValue; // no start → assume active
    if (!start.isBefore(nextMonthStart)) return 0; // hasn't started yet
    final endRaw = t.leaseEndIso.trim();
    if (endRaw.isEmpty) return t.rentAmountValue;
    final end = _parseCalendarDay(endRaw);
    if (end == null) return t.rentAmountValue;
    if (!end.isBefore(monthStart)) return t.rentAmountValue; // overlaps month
    return 0; // ended before this month
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
      // Checked-out stays off Home cards; cancelled stays so the badge can flip.
      if (item.isCheckedOut) continue;
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
    var properties = <PropertyRecord>[];

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
        // Keep cancelled so Home can show Cancelled; drop check-outs only.
        if (item.isCheckedOut) continue;
        merged[item.bookingKey] = item;
      }
    } catch (_) {}

    try {
      properties = await _propertyLocal.getAllVisibleNewestFirst(
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

    return merged.values.map((item) {
      final imageUrl = resolveBnbBookingPropertyImage(
        listingId: item.listingId,
        propertyLabel: item.propertyType,
        properties: properties,
        existingImageUrl: item.imageUrl,
      );
      if (imageUrl.isEmpty || imageUrl == item.imageUrl) return item;
      return item.copyWith(imageUrl: imageUrl);
    }).toList();
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

  Future<void> addListing() async {
    final saved = await Get.toNamed(Routes.ADD_LISTING);
    if (saved == true) {
      await loadHomeData(refresh: true);
    }
  }

  void properties() => Get.toNamed(Routes.MY_PROPERTIES);

  /// Same destination as Snapshot "Tenants" / Shortcuts "Tenants".
  void tenants() => openPeople();

  void sendSmsWhatsapp() =>
      Get.toNamed(Routes.SEND_SMS, arguments: const {'workspace': ''});

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

  void calendar() => Get.toNamed(Routes.HOST_CALENDAR);

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void tasks() => Get.toNamed(Routes.MAINTENANCE_TASKS);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  Future<void> reports() async {
    await Get.toNamed(Routes.REPORTS_HUB);
  }

  void designStudio() => Get.toNamed(Routes.INTERIOR_DESIGN_STUDIO);

  void designMoodboards() => Get.toNamed(Routes.DESIGN_MOODBOARDS);

  void aiManager() => Get.toNamed(Routes.AI_MANAGER);

  void openBookings() => Get.toNamed(Routes.ALL_BOOKINGS);

  void openProperties() => Get.toNamed(Routes.MY_PROPERTIES);

  void openBnbProperties() => Get.toNamed(
        Routes.MY_PROPERTIES,
        arguments: {'workspaceFilter': 'bnb'},
      );

  void openRentProperties() => Get.toNamed(
        Routes.MY_PROPERTIES,
        arguments: {'workspaceFilter': 'rent'},
      );

  void openAllTenants() => openPeople();

  void aiInsights() =>
      Get.toNamed(Routes.AI_INSIGHTS, arguments: const {'source': 'insights'});

  void aiAutomations() => Get.toNamed(
    Routes.AI_AUTOMATIONS,
    arguments: const {'source': 'automations'},
  );

  void documents() => Get.toNamed(Routes.PROPERTY_VAULT);

  /// Workspace arg for payment lists: `rent`, `bnb`, or `''` (all).
  String _paymentsWorkspaceArg() {
    final showBnb = showBnbHomeContent;
    final showRent = showRentHomeContent;
    if (showBnb && !showRent) return 'bnb';
    if (showRent && !showBnb) return 'rent';
    return '';
  }

  void openTodayRevenue() => Get.toNamed(
        Routes.RENT_MANAGE_PAYMENTS,
        arguments: {'ws': _paymentsWorkspaceArg()},
      );

  /// Full payment list matching the home Recent payments section.
  void openAllRecentPayments() {
    final newest = visibleRecentPayments.isEmpty
        ? null
        : visibleRecentPayments.first.paidLocalCalendarOrCreated();
    Get.toNamed(
      Routes.RENT_MANAGE_PAYMENTS,
      arguments: {
        'ws': _paymentsWorkspaceArg(),
        'allMonths': true,
        if (newest != null) 'focusMonth': newest,
      },
    );
  }

  void openScheduledMaintenance() => calendar();

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
  /// `occupiedUnits / totalUnits * 100`, capped at 100.
  ///
  /// A unit is **occupied** on a given day when it has a tenant whose lease
  /// period covers that day (`leaseStart ≤ day ≤ leaseEnd`).  Open-ended
  /// leases (empty `leaseEndIso`) are treated as still active.
  ///
  /// Distinct `propertyRef::unitId` keys are used so a unit shared by
  /// overlapping tenants is only counted once per day.
  void _assignWeeklyOccupancy(
      Iterable<TenantRecord> tenants,
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
      final occupiedKeys = <String>{};
      for (final t in tenants) {
        if (!_tenantOccupiesCalendarDay(t, day)) continue;
        final uid = t.apartmentUnitId.trim();
        final key = uid.isNotEmpty
            ? '${t.propertyRef}::$uid'
            : '${t.propertyRef}::tenant_${t.id}';
        occupiedKeys.add(key);
      }
      pct[i] = ((occupiedKeys.length / totalUnits) * 100).clamp(0.0, 100.0);
    }
    weeklyOccupancyPercent.assignAll(pct);
  }

  /// Returns true when [t]'s lease period covers [day] (inclusive on both ends).
  static bool _tenantOccupiesCalendarDay(TenantRecord t, DateTime day) {
    final start = _parseCalendarDay(t.leaseStartIso.trim());
    if (start == null) return false; // no start date → skip
    if (day.isBefore(start)) return false;
    final endRaw = t.leaseEndIso.trim();
    if (endRaw.isEmpty) return true; // open-ended lease
    final end = _parseCalendarDay(endRaw);
    if (end == null) return true; // unparseable end → treat as open-ended
    return !day.isAfter(end); // inclusive end
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
        _restampCancelledFromOverrides();
        await DashboardController.refreshIfRegistered();
        await HostCalendarController.refreshIfRegistered();
      }
    });
  }

  /// After a details-pop reload, force Cancelled badges from the override store
  /// so a stale API row cannot briefly show Confirmed again.
  void _restampCancelledFromOverrides() {
    final overrides = BnbBookingOverridesStore();
    bool cancelled(CheckInItem i) => overrides.isCancelledForAny([
          i.bookingKey,
          if ((i.bookingId ?? '').trim().isNotEmpty) i.bookingId!.trim(),
          i.guestCheckInKey,
        ]);

    List<CheckInItem> patch(List<CheckInItem> list) => list
        .map(
          (i) => cancelled(i)
              ? i.copyWith(isCancelled: true, isConfirmed: false)
              : i,
        )
        .toList();

    checkIns.assignAll(patch(checkIns.toList()));
    checkInsToday.assignAll(patch(checkInsToday.toList()));
    checkOutsToday.assignAll(patch(checkOutsToday.toList()));
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

  /// Remote is the source of truth here: a freshly installed app (or one
  /// that just logged in on a new device) has an empty local property cache
  /// even when the account genuinely has properties on the server. We only
  /// fall back to the local cache when a remote call itself fails
  /// (offline, timeout, error response) — never merely because the remote
  /// payload didn't match one of the known shapes with data in it.
  ///
  /// IMPORTANT: the app has two independent property data models on the
  /// backend — `/api/listings` (Listing entity) and `/api/properties`
  /// (Property entity, written by AddListingController.saveProperty(), which
  /// is what the Add Property form and quick-add wizard actually call). Both
  /// must be checked or accounts whose properties only exist in one table
  /// would incorrectly see the "Add first property" empty state.
  Future<bool> _hasAtLeastOneProperty() async {
    bool? listingsEmpty;
    bool? propertiesEmpty;

    try {
      final res = await _repository.getMyListings();
      final remoteHasListings = _extractHasListings(res.data);
      if (kDebugMode) {
        debugPrint(
          '[HasAnyProperty] /api/listings responseCode=${res.responseCode} '
          'dataType=${res.data.runtimeType} '
          'dataPreview=${_previewData(res.data)} '
          'remoteHasListings=$remoteHasListings',
        );
      }
      if (remoteHasListings) return true;
      listingsEmpty = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HasAnyProperty] /api/listings call threw: $e');
      }
      // Network/parse failure — inconclusive, may fall back to local below.
    }

    try {
      final res = await _repository.getMyProperties();
      final remoteHasProperties = _extractHasProperties(res.data);
      if (kDebugMode) {
        debugPrint(
          '[HasAnyProperty] /api/properties responseCode=${res.responseCode} '
          'dataType=${res.data.runtimeType} '
          'dataPreview=${_previewData(res.data)} '
          'remoteHasProperties=$remoteHasProperties',
        );
      }
      if (remoteHasProperties) return true;
      propertiesEmpty = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HasAnyProperty] /api/properties call threw: $e');
      }
    }

    if (listingsEmpty == true && propertiesEmpty == true) {
      // Both remote sources answered successfully and explicitly report
      // zero properties — trust them rather than a possibly-stale local cache.
      return false;
    }

    // At least one remote source was inconclusive (threw) — fall back to
    // the local cache rather than risk a false "no properties" empty state.
    final localRows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: '',
      workspaceType: '',
    );
    if (kDebugMode) {
      debugPrint(
        '[HasAnyProperty] falling back to local cache: '
        '${localRows.length} row(s)',
      );
    }
    return localRows.isNotEmpty;
  }

  String _previewData(dynamic data) {
    final s = data.toString();
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }

  bool _extractHasListings(dynamic data) {
    if (data is List) return data.isNotEmpty;
    if (data is Map) {
      final content = data['content'];
      if (content is List && content.isNotEmpty) return true;
      final listings = data['listings'];
      if (listings is List && listings.isNotEmpty) return true;
    }
    return false;
  }

  bool _extractHasProperties(dynamic data) {
    if (data is List) return data.isNotEmpty;
    if (data is Map) {
      final properties = data['properties'];
      if (properties is List && properties.isNotEmpty) return true;
      final content = data['content'];
      if (content is List && content.isNotEmpty) return true;
    }
    return false;
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
    if (!GetxInstanceProbe.isAlive<HomeController>()) return;
    await Get.find<HomeController>().loadHomeData(
      refresh: true,
      force: true,
    );
  }

  /// Immediately marks matching Today cards as cancelled (badge flip) before
  /// a full reload finishes — avoids a stale "Confirmed" chip after cancel.
  static void applyCancelledBookingLocally(Iterable<String> keys) {
    if (!GetxInstanceProbe.isAlive<HomeController>()) return;
    Get.find<HomeController>()._applyCancelledBookingLocally(keys);
  }

  void _applyCancelledBookingLocally(Iterable<String> keys) {
    final keySet = keys.map((k) => k.trim()).where((k) => k.isNotEmpty).toSet();
    if (keySet.isEmpty) return;

    bool matches(CheckInItem i) =>
        keySet.contains(i.bookingKey) ||
        keySet.contains((i.bookingId ?? '').trim()) ||
        keySet.contains(i.guestCheckInKey);

    List<CheckInItem> patch(List<CheckInItem> list) => list
        .map(
          (i) => matches(i)
              ? i.copyWith(isCancelled: true, isConfirmed: false)
              : i,
        )
        .toList();

    checkIns.assignAll(patch(checkIns.toList()));
    checkInsToday.assignAll(patch(checkInsToday.toList()));
    checkOutsToday.assignAll(patch(checkOutsToday.toList()));
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
