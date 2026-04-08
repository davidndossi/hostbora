import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

class HomeController extends BaseController with GetTickerProviderStateMixin {
  final unreadCount = 0.obs;

  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());
  final WorkspaceContextService _workspaceContext =
      Get.find<WorkspaceContextService>();
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  late String username;
  late TabController tabController;

  final roles = [].obs;
  final userId = ''.obs;
  final communityId = ''.obs;
  final isAdmin = false.obs;
  final isLeader = false.obs;

  Timer? _debounce;

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
    final res = await _repository.getHomeOverview();
    if (res.responseCode == '0' && res.data != null) {
      final d = res.data! as Map<String, dynamic>;
      activeBookings.value = (d['activeBookings'] as num?)?.toInt() ?? 0;
      monthlyRevenue.value = (d['monthlyRevenue'] as String?) ?? 'TZS 0';
      bookingsChange.value = (d['bookingsChange'] as String?) ?? '+0% from last month';
      revenueChange.value = (d['revenueChange'] as String?) ?? '+0% from last month';
    }
  }

  Future<void> _loadUpcomingCheckIns() async {
    final res = await _repository.getUpcomingBookings();
    if (res.responseCode != '0' || res.data == null) return;
    final list = res.data!['bookings'] as List<dynamic>? ?? [];
    final items = list.map((e) {
      final m = e as Map<String, dynamic>;
      final checkIn = m['checkIn'] as String? ?? '';
      final checkOut = m['checkOut'] as String? ?? '';
      final nights = (m['numberOfNights'] as num?)?.toInt() ?? 0;
      final dates = _formatDates(checkIn, checkOut, nights);
      return CheckInItem(
        bookingId: m['bookingId'] as String?,
        imageUrl: m['imageUrl'] as String? ?? '',
        guestName: m['guestName'] as String? ?? '',
        guestAvatarUrl: m['guestAvatarUrl'] as String? ?? '',
        propertyType: m['propertyType'] as String? ?? m['propertyName'] as String? ?? '',
        dates: dates,
        isConfirmed: m['isConfirmed'] as bool? ?? false,
      );
    }).toList();
    checkIns.assignAll(items);
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

  void addNewBooking() => Get.toNamed(Routes.ADD_NEW_BOOKING);

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

  void addExpense() => Get.toNamed(Routes.ADD_EXPENSE);

  void addPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);
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