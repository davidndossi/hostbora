import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../core/utils/tenant_rent_billing.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';

/// True when [leaseStart]–[leaseEnd] overlaps half-open calendar month
/// [monthStart, nextMonthStart) using date-only boundaries (avoids UTC drift).
/// Duplicated from [HomeController] — private members cannot be shared across libraries.
bool _leaseOverlapsCalendarMonth({
  required DateTime leaseStart,
  required DateTime leaseEnd,
  required DateTime monthStart,
  required DateTime nextMonthStart,
}) {
  final ls = DateTime(leaseStart.year, leaseStart.month, leaseStart.day);
  final le = DateTime(leaseEnd.year, leaseEnd.month, leaseEnd.day);
  final ws = DateTime(monthStart.year, monthStart.month, monthStart.day);
  final we =
      DateTime(nextMonthStart.year, nextMonthStart.month, nextMonthStart.day);
  return ls.isBefore(we) && le.isAfter(ws);
}

/// Same date-only parsing as home / reports occupancy geometry.
DateTime? _parseCalendarDay(String raw) {
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

class HostDashboardController extends BaseController {
  HostDashboardController()
      : _workspaceContext = Get.find<WorkspaceContextService>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _bnbTenantLocal = Get.find<TenantLocalDataSource>(),
        _rentIncomeLocal = Get.find<IncomeLocalDataSource>(),
        _pendingBookingsStore = PendingBookingsStore();

  final WorkspaceContextService _workspaceContext;
  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _bnbTenantLocal;
  final IncomeLocalDataSource _rentIncomeLocal;
  final PendingBookingsStore _pendingBookingsStore;

  late final BnbBookingPendingLoader _pendingBookingLoader =
      BnbBookingPendingLoader(
    syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
  );

  final activeBookings = 0.obs;
  final monthlyRevenue = ''.obs;
  final bookingsChange = ''.obs;
  final revenueChange = ''.obs;
  final checkIns = <CheckInItem>[].obs;
  final dashboardLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _workspaceContext.switchWorkspace('bnb');
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    dashboardLoading.value = true;
    try {
      await Future.wait([
        _loadOverview(),
        _loadUpcomingCheckIns(),
      ]);
    } catch (e) {
      if (e is Exception) {
        showErrorMessage(e.toString());
      }
    } finally {
      dashboardLoading.value = false;
    }
  }

  Future<void> _loadOverview() async {
    var remoteActive = 0;
    var remoteRevenueLabel = '';
    String? remoteBookingsChange;
    try {
      final res = await _repository.getHomeOverview();
      if (res.responseCode == '0' && res.data != null) {
        final d = res.data! as Map<String, dynamic>;
        remoteActive = (d['activeBookings'] as num?)?.toInt() ?? 0;
        remoteRevenueLabel =
            (d['monthlyRevenue'] as String?)?.trim() ?? '';
        remoteBookingsChange = (d['bookingsChange'] as String?)?.trim();
      }
    } catch (_) {}

    final pendingMaps = await _pendingBookingLoader.loadAll();
    final localActive = pendingMaps.length;

    final tenantRows =
        await _bnbTenantLocal.getAllForBnbWorkspaceByPropertyRefJoin();
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
      final incomeRows =
          await _rentIncomeLocal.getAllForBnbWorkspaceByPropertyRefJoin();
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

    activeBookings.value =
        localActive > remoteActive ? localActive : remoteActive;
    final fx = Get.find<CurrencyService>();
    if (combinedMonthly > 0) {
      monthlyRevenue.value = fx.formatBase(combinedMonthly.round());
    } else if (remoteRevenueLabel.isNotEmpty) {
      monthlyRevenue.value = remoteRevenueLabel;
    } else {
      monthlyRevenue.value = fx.formatBase(0);
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

  String _formatMoMPercent(double current, double previous) {
    if (previous.abs() < 0.0001) {
      if (current.abs() < 0.0001) return '+0% from last month';
      return '+100% from last month';
    }
    final pct = ((current - previous) / previous.abs()) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}% from last month';
  }

  Future<void> _loadUpcomingCheckIns() async {
    final all = await _mergeActiveBnbBookings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = <CheckInItem>[];
    for (final item in all) {
      if (item.isInactive) continue;
      final ci = _parseCalendarDay(item.checkInIso);
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

    upcoming.sort(sortByCheckIn);
    checkIns.assignAll(upcoming);
  }

  Future<List<CheckInItem>> _mergeActiveBnbBookings() async {
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};

    try {
      final res = await _repository.getUpcomingBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (BookingApiResponse.isSuccess(res.responseCode)) {
        rows = BookingApiResponse.parseBookingsList(data);
      }
      for (final e in rows) {
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

  void viewTrends() => Get.toNamed(Routes.FINANCIAL_OVERVIEW);

  void seeAllCheckIns() => Get.toNamed(Routes.ALL_BOOKINGS);

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void addNewBooking() {
    Get.toNamed(Routes.ADD_NEW_BOOKING)?.then((saved) async {
      if (saved == true) {
        await HostCalendarController.refreshIfRegistered();
        await DashboardController.refreshIfRegistered();
        await loadDashboardData();
      }
    });
  }

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void viewCalendar() => Get.toNamed(Routes.HOST_CALENDAR);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void reports() => Get.toNamed(Routes.REPORTS_HUB);

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item)?.then((_) {
        loadDashboardData();
      });
}
