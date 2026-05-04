import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:paa_yangu/app/core/values/text_styles.dart';

import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
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
        _loadUpcomingCheckIns(),
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

    final pendingLocalBookings = _pendingBookingsStore.count;
    final localActive = pendingLocalBookings;

    final tenantRows = await _bnbTenantLocal.getAllNewestFirst();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    double localMonthlyRevenue = 0;
    double prevMonthlyRevenue = 0;
    var localCurrentBookings = 0;
    var localPreviousBookings = 0;
    for (final t in tenantRows) {
      DateTime d;
      try {
        d = DateTime.parse(t.leaseStartIso);
      } catch (_) {
        d = DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
      }
      if (!d.isBefore(monthStart) && d.isBefore(nextMonthStart)) {
        localMonthlyRevenue += t.rentAmountValue;
        localCurrentBookings++;
      } else if (!d.isBefore(prevMonthStart) && d.isBefore(monthStart)) {
        prevMonthlyRevenue += t.rentAmountValue;
        localPreviousBookings++;
      }
    }

    double bnbLocalIncomeThisMonth = 0;
    double bnbLocalIncomePrevMonth = 0;
    try {
      final incomeRows = await _rentIncomeLocal.getAllNewestFirst();
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
          'TZS ${NumberFormat('#,###', 'en_US').format(combinedMonthly.round())}';
    } else {
      monthlyRevenue.value = remoteRevenueLabel;
    }
    bookingsChange.value =
        (remoteBookingsChange != null && remoteBookingsChange.isNotEmpty)
            ? remoteBookingsChange
            : _formatMoMPercent(localCurrentBookings.toDouble(), localPreviousBookings.toDouble());
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
        final m = Map<String, dynamic>.from(e);
        final checkIn = (m['checkIn'] ?? '').toString();
        final checkOut = (m['checkOut'] ?? '').toString();
        final nights = (m['numberOfNights'] as num?)?.toInt() ?? 0;
        final id = (m['bookingId'] ?? '${m['guestName']}_$checkIn').toString();
        merged[id] = CheckInItem(
          bookingId: m['bookingId'] as String?,
          imageUrl: (m['imageUrl'] ?? '').toString(),
          guestName: (m['guestName'] ?? '').toString(),
          guestAvatarUrl: (m['guestAvatarUrl'] ?? '').toString(),
          propertyType: (m['propertyType'] ?? m['propertyName'] ?? '').toString(),
          dates: _formatDates(checkIn, checkOut, nights),
          isConfirmed: (m['isConfirmed'] as bool?) ?? false,
        );
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllNewestFirst();
      final pending = _pendingBookingsStore.load();
      for (final m in pending) {
        final listingId = (m['listingId'] ?? '').toString().trim();
        final checkIn = (m['checkIn'] ?? '').toString();
        final checkOut = (m['checkOut'] ?? '').toString();
        if (listingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) continue;
        final property = properties.firstWhereOrNull(
          (p) => p.propertyRef.trim() == listingId || 'local_${p.id}' == listingId,
        );
        final propertyLabel = property?.propertyName.trim().isNotEmpty == true
            ? property!.propertyName.trim()
            : (property?.propertyLocation ?? 'Property');
        final localId = 'local_${m['createdAt'] ?? '${listingId}_$checkIn'}';
        merged[localId] = CheckInItem(
          bookingId: localId,
          imageUrl: '',
          guestName: (m['guestName'] ?? '').toString(),
          guestAvatarUrl: '',
          propertyType: propertyLabel,
          dates: _formatDates(checkIn, checkOut, 0),
          isConfirmed: true,
        );
      }
    } catch (_) {}

    checkIns.assignAll(merged.values.toList());
  }

  String _formatDates(String checkIn, String checkOut, int nights) {
    try {
      final ci = DateTime.tryParse(checkIn);
      final co = DateTime.tryParse(checkOut);
      if (ci != null && co != null) {
        final fmt = DateFormat('MMM d');
        final n = nights > 0 ? nights : co.difference(ci).inDays;
        return '${fmt.format(ci)} - ${fmt.format(co)} • $n Night${n == 1 ? '' : 's'}';
      }
    } catch (_) {}
    return '$checkIn - $checkOut';
  }

  void viewTrends() {
    // TODO: navigate to trends screen
  }

  void seeAllCheckIns() => Get.toNamed(Routes.ALL_BOOKINGS);

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void properties() => Get.toNamed(Routes.MY_PROPERTIES);

  Future<void> addNewBooking() async {
    await _guardPropertyBeforeAction(
      onProceed: () async {
        await Get.toNamed(Routes.ADD_NEW_BOOKING);
        await _loadUpcomingCheckIns();
      },
    );
  }

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void tasks() => Get.toNamed(Routes.MAINTENANCE_TASKS);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void reports() => Get.toNamed(Routes.EXPENSE_ANALYSIS);

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
        await Get.toNamed(Routes.RENT_ADD_NEW_EXPENSE);
      },
    );
  }

  Future<void> addPayment() async {
    await _guardPropertyBeforeAction(
      onProceed: () async {
        final saved = await Get.toNamed(Routes.RENT_ADD_INCOME_FORM);
        if (saved == true) {
          await _loadOverview();
        }
      },
    );
  }

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);

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
      final localRows = await _propertyLocal.getAllNewestFirst();
      return localRows.isNotEmpty;
    } catch (_) {
      final localRows = await _propertyLocal.getAllNewestFirst();
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

class CheckInItem {
  final String? bookingId;
  final String imageUrl;
  final String guestName;
  final String guestAvatarUrl;
  final String propertyType;
  final String dates;
  final bool isConfirmed;

  CheckInItem({
    this.bookingId,
    required this.imageUrl,
    required this.guestName,
    required this.guestAvatarUrl,
    required this.propertyType,
    required this.dates,
    required this.isConfirmed,
  });
}