import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/announcement.dart';
import '../../../data/model/community.dart';
import '../../../data/model/event.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/login_response.dart';
import '../../../data/model/post.dart';
import '../../../data/model/request.dart';
import '../../../data/model/user_profile_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

class HomeController extends BaseController with GetTickerProviderStateMixin {
  final unreadCount = 0.obs;

  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());
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

  final activeBookings = 12;
  final monthlyRevenue = '\$4,250';
  final bookingsChange = '+15% from last month';
  final revenueChange = '+8.2% from last month';

  final checkIns = [
    CheckInItem(
      imageUrl: 'https://placehold.co/280x160/e0f7f6/00695c.png?text=Downtown+Loft',
      guestName: 'Sarah M.',
      guestAvatarUrl: 'https://placehold.co/48x48.png',
      propertyType: 'Downtown Loft',
      dates: 'Oct 12 - Oct 15 • 3 Nights',
      isConfirmed: true,
    ),
    CheckInItem(
      imageUrl: 'https://placehold.co/280x160/e3f2fd/1565c0.png?text=Seaside',
      guestName: 'James',
      guestAvatarUrl: 'https://placehold.co/48x48.png',
      propertyType: 'Seaside',
      dates: 'Oct 14 - Oct 18 • 4 Nights',
      isConfirmed: false,
    ),
  ];

  void viewTrends() {
    // TODO: navigate to trends screen
  }

  void seeAllCheckIns() {
    // TODO: navigate to check-ins list
  }

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void properties() => Get.toNamed(Routes.MY_PROPERTIES);

  void addNewBooking() => Get.toNamed(Routes.ADD_NEW_BOOKING);

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void tasks() => Get.toNamed(Routes.MAINTENANCE_TASKS);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void reports() => Get.toNamed(Routes.EXPENSE_ANALYSIS);

  void documents() => Get.toNamed(Routes.PROPERTY_VAULT);

  void addExpense() => Get.toNamed(Routes.ADD_EXPENSE);

  void addPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);
}

class CheckInItem {
  final String imageUrl;
  final String guestName;
  final String guestAvatarUrl;
  final String propertyType;
  final String dates;
  final bool isConfirmed;

  CheckInItem({
    required this.imageUrl,
    required this.guestName,
    required this.guestAvatarUrl,
    required this.propertyType,
    required this.dates,
    required this.isConfirmed,
  });
}