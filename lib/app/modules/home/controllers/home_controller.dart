import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/access/plan_agents.dart';
import '../../../core/service/launch_prompt_gate.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../core/utils/bnb_property_listing.dart';
import '../../../core/utils/expected_month_rent.dart';
import '../../../core/utils/getx_instance_probe.dart';
import '../../../core/utils/overdue_occupants.dart';
import '../../../core/utils/tenant_rent_billing.dart';
import '../../../core/utils/unlinked_payments.dart';
import '../../../core/utils/property_unit_count.dart';
import '../../../core/values/text_styles.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/synced_entity_store.dart';
import '../../../data/local/bnb_booking_overrides_store.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/deleted_properties_store.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/lease_income_extension.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
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

  /// True only before the first successful [loadHomeData] (legacy; Home now
  /// shows the shell immediately and uses per-section loaders instead).
  final homeInitialLoading = false.obs;

  /// Pull-to-refresh indicator on BnB home.
  final homeRefreshing = false.obs;

  final homeHasLoaded = false.obs;

  /// Per-section loaders — Home shell renders immediately; each block spins
  /// until its own data arrives.
  final todaySectionLoading = true.obs;
  final snapshotSectionLoading = true.obs;
  final recentPaymentsSectionLoading = true.obs;
  final presenceLoading = true.obs;

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

  /// Raw base-currency amounts behind the labels above (Home summary card).
  final expectedIncomeValue = 0.0.obs;
  final collectedIncomeValue = 0.0.obs;

  /// Tenants billed this month, and how many of them have paid it in full.
  final billedTenantsCount = 0.obs;
  final paidTenantsCount = 0.obs;

  /// Income paid this month that no tenant owns (not part of rent collection).
  final otherIncomeValue = 0.0.obs;

  /// Rent payments of any date that are not linked to a tenant.
  final unlinkedPaymentsCount = 0.obs;

  /// BnB income received this calendar month (base currency).
  final bnbRevenueValue = 0.0.obs;

  /// Masks the Home summary card amounts; persisted across launches.
  final hideHomeAmounts = false.obs;

  /// Newest income rows (unfiltered); use [visibleRecentPayments] for UI.
  final recentPayments = <IncomeRecord>[].obs;

  /// Combined overdue rent tenants and unpaid BnB guests.
  final overdueOccupants = <OverdueOccupant>[].obs;

  /// True when any income row exists, including dates outside Free-plan history.
  final hasRecordedPayment = false.obs;

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
    unawaited(_initHideHomeAmounts());
    loadHomeData();
  }

  Future<void> _initHideHomeAmounts() async {
    try {
      hideHomeAmounts.value = await _preferenceManager.getBool(
        PreferenceManager.keyHomeHideAmounts,
      );
    } catch (_) {}
  }

  Future<void> toggleHideHomeAmounts() async {
    final next = !hideHomeAmounts.value;
    hideHomeAmounts.value = next;
    try {
      await _preferenceManager.setBool(
        PreferenceManager.keyHomeHideAmounts,
        next,
      );
    } catch (_) {}
  }

  Future<void> _initHomeWorkspaceFilter() async {
    try {
      final saved = await _preferenceManager.getString(
        PreferenceManager.keyHomeWorkspaceFilter,
        defaultValue: '',
      );
      if (saved == 'all' || saved == 'bnb' || saved == 'rent') {
        homeWorkspaceFilter.value = saved;
      }
      // No saved choice keeps the field's own default of `all`. This used to
      // fall back to the workspace preference, which nothing in onboarding
      // ever set — so it resolved to `bnb` and silently hid a long-term
      // landlord's rent data behind a chip they had never touched. Showing
      // everything is only noisier for hosts who genuinely run both, and
      // those are exactly the hosts who get the chips to narrow it.
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

  /// Overdue people for the current home workspace filter.
  List<OverdueOccupant> get visibleOverdueOccupants {
    final showBnb = showBnbHomeContent;
    final showRent = showRentHomeContent;
    Iterable<OverdueOccupant> rows = overdueOccupants;
    if (showBnb && !showRent) {
      rows = rows.where((r) => r.isBnb);
    } else if (showRent && !showBnb) {
      rows = rows.where((r) => !r.isBnb);
    }
    return rows.toList();
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
    todayExpandedKey.value = todayExpandedKey.value == key ? null : key;
  }

  Future<void>? _loadHomeInFlight;
  DateTime? _lastHomeLoadAt;

  /// Cap for Home API calls — Dio's global 60s timeout left Home skeleton
  /// stuck for a minute+ when the network was slow or endpoints hung.
  static const Duration _homeNetworkTimeout = Duration(seconds: 10);

  Future<T?> _homeApi<T>(Future<T> future) async {
    try {
      return await future.timeout(_homeNetworkTimeout);
    } catch (_) {
      return null;
    }
  }

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
    }
    // Always show the Home shell; sections spin individually.
    homeInitialLoading.value = false;
    todaySectionLoading.value = true;
    snapshotSectionLoading.value = true;
    recentPaymentsSectionLoading.value = true;
    presenceLoading.value = true;

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
      // Each section clears its own spinner when ready so the UI updates
      // progressively instead of waiting for the slowest API.
      await Future.wait([
        _loadTodaySection(),
        _loadSnapshotSection(),
        _loadRecentPaymentsSection(),
        _loadPresenceSection(),
      ]);
      await _resolveExperienceStage();
      _lastHomeLoadAt = DateTime.now();
    } catch (e) {
      if (e is Exception) {
        showErrorMessage(e.toString());
      }
    } finally {
      todaySectionLoading.value = false;
      snapshotSectionLoading.value = false;
      recentPaymentsSectionLoading.value = false;
      presenceLoading.value = false;
      homeInitialLoading.value = false;
      homeRefreshing.value = false;
      homeHasLoaded.value = true;
      if (!refresh) {
        unawaited(_maybeShowPropertiesTabSpotlight());
      }
    }
  }

  Future<void> _loadTodaySection() async {
    try {
      await Future.wait([_loadBookingLists(), _loadUpcomingMaintenance()]);
    } finally {
      todaySectionLoading.value = false;
    }
  }

  Future<void> _loadSnapshotSection() async {
    try {
      await Future.wait([
        _loadOverview(),
        _loadBnbOverviewStats(),
        _loadRentOverviewStats(),
        _loadPortfolioRole(),
        _loadOverdueOccupants(),
      ]);
      await _syncPortfolioTenantStats();
    } finally {
      snapshotSectionLoading.value = false;
      unawaited(_loadPaidTenantStats());
      unawaited(_loadUnlinkedPayments());
    }
  }

  Future<void> _loadRecentPaymentsSection() async {
    try {
      await _loadRecentPayments();
    } finally {
      recentPaymentsSectionLoading.value = false;
    }
  }

  Future<void> _loadPresenceSection() async {
    try {
      await _loadPropertyPresence();
    } finally {
      presenceLoading.value = false;
    }
  }

  Future<void> _resolveExperienceStage() async {
    if (!hasAnyProperty.value) {
      homeExperienceStage.value = HomeExperienceStage.noProperties;
      return;
    }
    try {
      final occupantAdded =
          rentTenantsCount.value > 0 || bnbBookingsCount.value > 0;
      final setupComplete = occupantAdded && hasRecordedPayment.value;
      if (setupComplete) {
        await _preferenceManager.setBool(
          PreferenceManager.keyHomeGetStartedComplete,
          true,
        );
      }
      final alreadyFinished = await _preferenceManager.getBool(
        PreferenceManager.keyHomeGetStartedComplete,
      );
      if (setupComplete || alreadyFinished) {
        homeExperienceStage.value = HomeExperienceStage.established;
        return;
      }
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
      final isFree =
          Get.currentRoute == Routes.MAIN &&
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
      final res = await _homeApi(_repository.getHomeOverview());
      if (res != null && res.responseCode == '0' && res.data != null) {
        final d = res.data! as Map<String, dynamic>;
        remoteActive = (d['activeBookings'] as num?)?.toInt() ?? 0;
        remoteRevenueLabel =
            (d['monthlyRevenue'] as String?) ?? CurrencyService.zeroLabel();
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
    bnbRevenueValue.value = combinedMonthly;

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
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
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

  static Future<void> _fillBookingsFromPhoneCache(
    BnbBookingMerge merge,
    Map<String, CheckInItem> merged,
  ) async {
    try {
      final cached = await SyncedEntityStore().load(
        SyncedEntityStore.bookingType,
      );
      for (final row in cached) {
        if (row.payload.isEmpty) continue;
        final item = merge.fromApiMap(row.payload);
        merged.putIfAbsent(item.bookingKey, () => item);
      }
    } catch (_) {}
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

    var loadedFromNetwork = false;
    try {
      final res = await _homeApi(_repository.getAllBookings());
      if (res != null && BookingApiResponse.isSuccess(res.responseCode)) {
        loadedFromNetwork = true;
        for (final m in BookingApiResponse.parseBookingsList(res.data)) {
          final item = merge.fromApiMap(m);
          if (item.isCancelled) continue;
          merged[item.bookingKey] = item;
        }
      }
    } catch (_) {}
    if (!loadedFromNetwork) {
      await _fillBookingsFromPhoneCache(merge, merged);
    }

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
    bnbTodayRevenue.value = Get.find<CurrencyService>().formatBase(
      todaySum.round(),
    );

    _assignWeeklyRevenue(incomes, weekStart);
  }

  /// Tenant count and occupancy for the Home summary, using the same rows
  /// My Properties shows on each listing (every workspace, not only rent).
  Future<void> _syncPortfolioTenantStats() async {
    try {
      final byRef = await _visiblePropertiesByRef();
      var tenants = 0;
      var units = 0;
      var occupied = 0;
      for (final entry in byRef.entries) {
        final unitCount = PropertyUnitCount.of(entry.value);
        final count = await _bnbTenantLocal.countByPropertyRef(entry.key);
        tenants += count;
        units += unitCount;
        if (unitCount > 0 && count > 0) {
          occupied += count > unitCount ? unitCount : count;
        }
      }
      totalPropertiesCount.value = byRef.length;
      totalUnitsCount.value = units;
      rentTenantsCount.value = tenants;
      final percent = units <= 0
          ? 0
          : ((occupied / units) * 100).round().clamp(0, 100);
      rentOccupancyRate.value = percent;
      bnbOccupancyRate.value = percent;
    } catch (_) {}
  }

  Future<void> _loadRentOverviewStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);

      await LeaseIncomeExtension.applyMissed();

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

      totalPropertiesCount.value = byRef.length;
      totalUnitsCount.value = byRef.values.fold<int>(
        0,
        (sum, p) => sum + PropertyUnitCount.of(p),
      );

      final allTenants = await _tenantsOnVisibleProperties(byRef);

      // Rent tenants contribute this month's contract rent. Each BnB unit
      // contributes its nightly rate, in base currency, times the days in
      // this month.
      var expectedIncome = 0.0;
      final cs = Get.find<CurrencyService>();
      final days = ExpectedMonthRent.daysInMonth(monthStart);
      final coveredTenantIds = <int>{};
      for (final property in byRef.values) {
        final bnbUnits = ExpectedMonthRent.bnbUnitsOf(
          property,
          daysInMonth: days,
        );
        final coverAll =
            bnbUnits.isNotEmpty &&
            ExpectedMonthRent.bnbUnitsCoverAllTenants(property);
        for (final unit in bnbUnits) {
          var nightly = unit.nightlyAmount;
          var currency = unit.currency;
          for (final tenant in allTenants) {
            if (!ExpectedMonthRent.tenantOnProperty(tenant, property)) continue;
            final onThisUnit =
                unit.matchesTenant(tenant) ||
                (bnbUnits.length == 1 && unit.unitId == 'main');
            if (onThisUnit || coverAll) coveredTenantIds.add(tenant.id);
            if (!onThisUnit || nightly > 0 || tenant.rentAmountValue <= 0) {
              continue;
            }
            nightly =
                ExpectedMonthRent.nightlyFrom(
                  tenant.rentAmountValue,
                  tenant.rentFrequency,
                  days,
                ) ??
                tenant.rentAmountValue;
            currency = tenant.rentCurrency;
          }
          if (nightly <= 0) continue;
          final nightlyBase = cs.toBaseAmount(
            inputAmount: nightly,
            inputCurrency: currency.trim().isEmpty
                ? cs.baseCurrency.value
                : currency,
          );
          expectedIncome += nightlyBase * days;
        }
      }
      for (final t in allTenants) {
        if (coveredTenantIds.contains(t.id)) continue;
        var tenantMonthly = ExpectedMonthRent.of(
          t,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
        );
        if (tenantMonthly <= 0) {
          tenantMonthly = _unitRentForTenant(t, byRef);
        }
        final tenantCurrency = t.rentCurrency.trim().toUpperCase();
        tenantMonthly = cs.toBaseAmount(
          inputAmount: tenantMonthly,
          inputCurrency: tenantCurrency.isEmpty
              ? cs.baseCurrency.value
              : tenantCurrency,
        );
        expectedIncome += tenantMonthly;
      }

      // Collected = prepaid rent allocated to this month, plus unmatched
      // income whose paid date falls in this calendar month (BnB / misc).
      var collectedIncome = 0.0;
      var otherIncome = 0.0;
      try {
        final rentIncomes = await _incomeLocal.getAllNewestFirst();
        final matchedIds = <int>{};
        for (final t in allTenants) {
          final rate = _baseRentFor(t, byRef, cs);
          var paidTotal = 0.0;
          for (final r in rentIncomes) {
            if (!TenantLedgerFinance.incomeMatchesTenant(r, t)) continue;
            paidTotal += r.amountValue;
            if (r.id > 0) matchedIds.add(r.id);
          }
          collectedIncome += TenantRentBilling.collectedInCalendarMonth(
            rentAmountValue: rate,
            rentFrequency: t.rentFrequency,
            leaseStartIso: t.leaseStartIso,
            leaseEndIso: t.leaseEndIso,
            paidTotal: paidTotal,
            monthStart: monthStart,
            nextMonthStart: nextMonthStart,
          );
        }
        for (final r in rentIncomes) {
          if (matchedIds.contains(r.id)) continue;
          final d = r.paidLocalCalendarOrCreated();
          final day = DateTime(d.year, d.month, d.day);
          if (!day.isBefore(monthStart) && day.isBefore(nextMonthStart)) {
            // A payment no tenant owns can't be allocated to months, so it is
            // reported as other income instead of inflating rent collected.
            // BnB income is per booking and still counts.
            if (UnlinkedPayments.countsTowardCollection(r)) {
              collectedIncome += r.amountValue;
            } else {
              otherIncome += r.amountValue;
            }
          }
        }
      } catch (_) {}

      if (collectedIncome <= 0) {
        collectionRate.value = 0;
      } else if (expectedIncome <= 0) {
        // Income is on the books and nothing is still expected.
        collectionRate.value = 100;
      } else {
        collectionRate.value = ((collectedIncome / expectedIncome) * 100)
            .round()
            .clamp(0, 100);
      }
      expectedIncomeLabel.value = cs.formatBaseShort(expectedIncome);
      collectedIncomeLabel.value = cs.formatBaseShort(collectedIncome);
      expectedIncomeValue.value = expectedIncome;
      collectedIncomeValue.value = collectedIncome;
      otherIncomeValue.value = otherIncome;
    } catch (_) {
      totalPropertiesCount.value = 0;
      totalUnitsCount.value = 0;
      rentOccupancyRate.value = 0;
      rentTenantsCount.value = 0;
      collectionRate.value = 0;
      expectedIncomeLabel.value = CurrencyService.zeroLabel();
      collectedIncomeLabel.value = CurrencyService.zeroLabel();
      expectedIncomeValue.value = 0;
      collectedIncomeValue.value = 0;
      otherIncomeValue.value = 0;
    }
  }

  /// Tenant's monthly rent in the base currency (unit rent when the tenant
  /// row has none).
  double _baseRentFor(
    TenantRecord t,
    Map<String, PropertyRecord> byRef,
    CurrencyService cs,
  ) {
    var rate = t.rentAmountValue;
    if (rate <= 0) rate = _unitRentForTenant(t, byRef);
    final currency = t.rentCurrency.trim().toUpperCase();
    return cs.toBaseAmount(
      inputAmount: rate,
      inputCurrency: currency.isEmpty ? cs.baseCurrency.value : currency,
    );
  }

  int _unlinkedRun = 0;

  /// Count of rent payments with no tenant, for the Home "link payments"
  /// prompt. Background task like [_loadPaidTenantStats]; never blocks Home.
  Future<void> _loadUnlinkedPayments() async {
    final run = ++_unlinkedRun;
    try {
      final tenants = await _bnbTenantLocal.getAllNewestFirst();
      final incomes = await _incomeLocal.getAllNewestFirst();
      final unlinked = await UnlinkedPayments.find(
        tenants: tenants,
        incomes: incomes,
      );
      if (run != _unlinkedRun) return;
      unlinkedPaymentsCount.value = unlinked.length;
    } catch (_) {
      // Prompt is optional; keep whatever was shown before.
    }
  }

  int _paidStatsRun = 0;

  /// "X of Y paid" for the Home summary pill. Runs after the card has already
  /// rendered, yields to the UI while it works, and never blocks Home loading;
  /// the pill simply appears when this finishes. Until then the previous
  /// result (if any) stays on screen so a refresh does not flicker.
  Future<void> _loadPaidTenantStats() async {
    final run = ++_paidStatsRun;
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final cs = Get.find<CurrencyService>();
      final byRef = await _visiblePropertiesByRef();
      final tenants = await _tenantsOnVisibleProperties(byRef);
      final incomes = await _incomeLocal.getAllNewestFirst();

      var billed = 0;
      var paid = 0;
      var visited = 0;
      for (final t in tenants) {
        // A newer refresh superseded this run.
        if (run != _paidStatsRun) return;
        // Tenant x income matching is quadratic; give frames back regularly.
        if (++visited % 15 == 0) await Future<void>.delayed(Duration.zero);

        final rate = _baseRentFor(t, byRef, cs);
        final due = TenantRentBilling.revenueInCalendarMonth(
          rentAmountValue: rate,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
        );
        if (due <= 0) continue;
        var paidTotal = 0.0;
        for (final r in incomes) {
          if (TenantLedgerFinance.incomeMatchesTenant(r, t)) {
            paidTotal += r.amountValue;
          }
        }
        final collected = TenantRentBilling.collectedInCalendarMonth(
          rentAmountValue: rate,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          paidTotal: paidTotal,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
        );
        billed++;
        if (collected >= due - 0.5) paid++;
      }
      if (run != _paidStatsRun) return;
      billedTenantsCount.value = billed;
      paidTenantsCount.value = paid;
    } catch (_) {
      // Pill is optional; keep whatever was shown before.
    }
  }

  Future<void> _loadOverdueOccupants() async {
    try {
      final rentTenants = await _bnbTenantLocal.getAllNewestFirstByWorkspace(
        'rent',
      );
      final bnbTenants = await _bnbTenantLocal.getAllNewestFirstByWorkspace(
        'bnb',
      );
      final incomes = await _incomeLocal.getAllNewestFirst();
      final properties = await _propertyLocal.getAllNewestFirst();
      overdueOccupants.assignAll(
        OverdueOccupants.fromRecords(
          rentTenants: rentTenants,
          bnbTenants: bnbTenants,
          incomes: incomes,
          properties: properties,
        ),
      );
    } catch (_) {
      overdueOccupants.clear();
    }
  }

  Future<void> _loadRecentPayments() async {
    try {
      final rows = await _incomeLocal.getAllNewestFirst();
      hasRecordedPayment.value = rows.isNotEmpty;
      recentPayments.assignAll(
        rows
            .where((row) {
              final paid = row.paidLocalCalendarOrCreated();
              return PlanAccess.isInPlanHistory(
                DateTime(paid.year, paid.month, paid.day),
              );
            })
            .take(20)
            .toList(),
      );
    } catch (_) {
      hasRecordedPayment.value = false;
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
      upcoming.sort((a, b) => a.scheduledDateIso.compareTo(b.scheduledDateIso));
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

  Future<List<TenantRecord>> _tenantsOnVisibleProperties(
    Map<String, PropertyRecord> byRef,
  ) async {
    final byId = <int, TenantRecord>{};
    for (final key in byRef.keys) {
      for (final tenant in await _bnbTenantLocal.listByPropertyRef(key)) {
        byId[tenant.id] = tenant;
      }
    }
    return byId.values.toList();
  }

  /// Unit contract rent when the tenant row has no amount of its own.
  double _unitRentForTenant(
    TenantRecord tenant,
    Map<String, PropertyRecord> byRef,
  ) {
    for (final property in byRef.values) {
      final raw = property.unitsJson.trim();
      if (raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final entry in decoded.whereType<Map>()) {
          final unitId = (entry['unitId'] ?? entry['id'] ?? '')
              .toString()
              .trim();
          final unitName = (entry['unitName'] ?? entry['name'] ?? '')
              .toString()
              .trim();
          final tenantUnitId = tenant.apartmentUnitId.trim();
          final tenantUnitName = tenant.unitLabel.trim();
          final idMatches =
              tenantUnitId.isNotEmpty &&
              unitId.isNotEmpty &&
              tenantUnitId == unitId;
          final nameMatches =
              tenantUnitName.isNotEmpty &&
              unitName.isNotEmpty &&
              tenantUnitName.toLowerCase() == unitName.toLowerCase();
          if (!idMatches && !nameMatches) continue;
          final rent = double.tryParse(
            (entry['unitRent'] ?? entry['rent'] ?? '')
                .toString()
                .replaceAll(',', '')
                .trim(),
          );
          if (rent != null && rent > 0) return rent;
        }
      } catch (_) {}
    }
    return 0;
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

    var loadedFromNetwork = false;
    try {
      final res = await _homeApi(_repository.getUpcomingBookings());
      final data = res?.data;
      List<dynamic> rows = const [];
      if (res != null &&
          res.responseCode == '0' &&
          data is Map &&
          data['bookings'] is List) {
        rows = data['bookings'] as List;
        loadedFromNetwork = true;
      } else if (res != null && res.responseCode == '0' && data is List) {
        rows = data;
        loadedFromNetwork = true;
      }
      for (final e in rows.whereType<Map>()) {
        final item = merge.fromApiMap(Map<String, dynamic>.from(e));
        // Keep cancelled so Home can show Cancelled; drop check-outs only.
        if (item.isCheckedOut) continue;
        merged[item.bookingKey] = item;
      }
    } catch (_) {}
    if (!loadedFromNetwork) {
      await _fillBookingsFromPhoneCache(merge, merged);
    }

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
    await Get.toNamed(Routes.REPORTS_MONTHLY_INCOME);
  }

  void designStudio() => Get.toNamed(Routes.INTERIOR_DESIGN_STUDIO);

  void designMoodboards() => Get.toNamed(Routes.DESIGN_MOODBOARDS);

  void aiManager() => Get.toNamed(Routes.AI_MANAGER);

  void openBookings() => Get.toNamed(Routes.ALL_BOOKINGS);

  void openProperties() => Get.toNamed(Routes.MY_PROPERTIES);

  void openBnbProperties() =>
      Get.toNamed(Routes.MY_PROPERTIES, arguments: {'workspaceFilter': 'bnb'});

  void openRentProperties() =>
      Get.toNamed(Routes.MY_PROPERTIES, arguments: {'workspaceFilter': 'rent'});

  void openAllTenants() => openPeople();

  static const overdueHomePreviewCount = 3;

  List<OverdueOccupant> get overdueHomePreview =>
      visibleOverdueOccupants.take(overdueHomePreviewCount).toList();

  void openOverdueOccupant(OverdueOccupant row) {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'id': '${row.tenantId}',
        'name': row.name,
        'property': row.propertyLabel,
        'ws': row.isBnb ? 'bnb' : 'rent',
        if (row.propertyRef.isNotEmpty) 'propertyRef': row.propertyRef,
      },
      arguments: {'ws': row.isBnb ? 'bnb' : 'rent'},
    );
  }

  Future<void> whatsappOverdueOccupant(OverdueOccupant row) async {
    final digits = row.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Hakuna namba ya simu'
            : 'Phone number not available',
      );
      return;
    }
    final phone = digits.startsWith('0') && digits.length >= 10
        ? '255${digits.substring(1)}'
        : digits;
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'WhatsApp haikufunguka.'
            : 'Could not open WhatsApp.',
      );
    }
  }

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

  Future<void> quickAddProperty() =>
      _runHomeQuickCreate(QuickHomeAction.addProperty);

  Future<void> quickAddTenant() =>
      _runHomeQuickCreate(QuickHomeAction.addTenant);

  Future<void> quickAddIncome() =>
      _runHomeQuickCreate(QuickHomeAction.addIncome);

  Future<void> quickAddExpense() =>
      _runHomeQuickCreate(QuickHomeAction.addExpense);

  Future<void> quickAddBooking() =>
      _runHomeQuickCreate(QuickHomeAction.addBooking);

  Future<void> quickSendReminder(BuildContext context) async {
    final saved = await startQuickSendReminder(context);
    if (saved == true) {
      await loadHomeData(refresh: true);
    }
  }

  Future<void> _runHomeQuickCreate(QuickHomeAction action) async {
    final saved = await runQuickHomeAction(action);
    if (saved == true) {
      await loadHomeData(refresh: true);
    }
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
  /// Local is checked first; the remote probe uses a short Home-specific
  /// timeout against `/api/properties`.
  Future<bool> _hasAtLeastOneProperty() async {
    final localRows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: '',
      workspaceType: '',
    );
    if (localRows.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[HasAnyProperty] local cache has ${localRows.length} row(s)',
        );
      }
      return true;
    }

    try {
      final res = await _homeApi(_repository.getMyProperties());
      if (res == null) {
        if (kDebugMode) {
          debugPrint('[HasAnyProperty] /api/properties timed out / failed');
        }
        return false;
      }
      final remoteHasProperties = _extractHasProperties(res.data);
      if (kDebugMode) {
        debugPrint(
          '[HasAnyProperty] /api/properties responseCode=${res.responseCode} '
          'dataType=${res.data.runtimeType} '
          'dataPreview=${_previewData(res.data)} '
          'remoteHasProperties=$remoteHasProperties',
        );
      }
      return remoteHasProperties;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HasAnyProperty] /api/properties call threw: $e');
      }
      return false;
    }
  }

  String _previewData(dynamic data) {
    final s = data.toString();
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }

  bool _extractHasProperties(dynamic data) => _extractHasPropertyPayload(data);

  bool _extractHasPropertyPayload(dynamic data) {
    if (data is List) return data.isNotEmpty;
    if (data is Map) {
      for (final key in ['properties', 'content', 'items', 'data']) {
        final nested = data[key];
        if (nested is List && nested.isNotEmpty) return true;
      }
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
    await Get.find<HomeController>().loadHomeData(refresh: true, force: true);
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
