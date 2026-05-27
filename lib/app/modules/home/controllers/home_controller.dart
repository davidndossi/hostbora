import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/values/text_styles.dart';

import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../core/utils/tenant_rent_billing.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
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
  final IncomeLocalDataSource _rentIncomeLocal =
      Get.find<IncomeLocalDataSource>();
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
  final homeLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _workspaceContext.switchWorkspace('bnb');
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    homeLoading.value = true;
    try {
      await Future.wait([
        _loadOverview(),
        _loadBookingLists(),
      ]);
    } catch (e) {
      if (e is Exception) {
        showErrorMessage(e.toString());
      }
    } finally {
      homeLoading.value = false;
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

    final tenantRows = await _bnbTenantLocal.getAllForBnbWorkspaceByPropertyRefJoin();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    double localMonthlyRevenue = 0;
    double prevMonthlyRevenue = 0;
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
        localMonthlyRevenue += TenantRentBilling.revenueInCalendarMonth(
          rentAmountValue: t.rentAmountValue,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
        );
        localCurrentBookings++;
      }
      if (_leaseOverlapsCalendarMonth(
            leaseStart: leaseStart,
            leaseEnd: leaseEnd,
            monthStart: prevMonthStart,
            nextMonthStart: monthStart,
          )) {
        prevMonthlyRevenue += TenantRentBilling.revenueInCalendarMonth(
          rentAmountValue: t.rentAmountValue,
          rentFrequency: t.rentFrequency,
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          monthStart: prevMonthStart,
          nextMonthStart: monthStart,
        );
        localPreviousBookings++;
      }
    }

    double bnbLocalIncomeThisMonth = 0;
    double bnbLocalIncomePrevMonth = 0;
    try {
      final incomeRows = await _rentIncomeLocal.getAllForBnbWorkspaceByPropertyRefJoin();
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

    final combinedMonthly = localMonthlyRevenue + bnbLocalIncomeThisMonth;
    final combinedPrev = prevMonthlyRevenue + bnbLocalIncomePrevMonth;

    activeBookings.value = localActive > remoteActive ? localActive : remoteActive;
    if (combinedMonthly > 0) {
      monthlyRevenue.value =
          Get.find<CurrencyService>().formatBase(combinedMonthly.round());
    } else {
      monthlyRevenue.value = remoteRevenueLabel;
    }
    bookingsChange.value =
        (remoteBookingsChange != null && remoteBookingsChange.isNotEmpty)
            ? remoteBookingsChange
            : _formatMoMPercent(localCurrentBookings.toDouble(), localPreviousBookings.toDouble());
    revenueChange.value = _formatMoMPercent(combinedMonthly, combinedPrev);
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
    final we = DateTime(nextMonthStart.year, nextMonthStart.month, nextMonthStart.day);
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
          userId: '', workspaceType: 'bnb');
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
      Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER, arguments: {'ws': 'bnb'});

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

  void aiInsights() => Get.toNamed(Routes.AI_INSIGHTS);

  void aiAutomations() => Get.toNamed(Routes.AI_AUTOMATIONS);

  void documents() => Get.toNamed(Routes.PROPERTY_VAULT);

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
    Get.toNamed(Routes.BOOKING_DETAILS, arguments: item)?.then((refreshed) async {
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
          userId: '', workspaceType: 'bnb');
      return localRows.isNotEmpty;
    } catch (_) {
      final localRows = await _propertyLocal.getAllVisibleNewestFirst(
          userId: '', workspaceType: 'bnb');
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
}