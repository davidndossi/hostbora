import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/community.dart';
import '../../../data/model/user_community.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class DashboardController extends BaseController {

  final isLoading = false.obs;
  final isMember = false.obs;
  final isLeader = false.obs;
  final isAdmin = false.obs;
  final showList = false.obs;

  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

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

  // Metric card data (Income view)
  final totalRevenue = '\$12,450.00';
  final totalRevenueChange = '+12.5%';
  final totalRevenueUp = true;

  final avgDailyRate = '\$215.00';
  final avgDailyRateChange = '-2.3%';
  final avgDailyRateUp = false;

  final netProfit = '\$8,120.00';
  final netProfitChange = '+8.1%';
  final netProfitUp = true;

  // Performance trends - current period (teal), previous period (orange)
  final currentTrendValues = [2.5, 3.2, 4.8, 3.5];
  final previousTrendValues = [2.8, 3.0, 3.2, 2.9];
  static const trendLabels = ['WEEK 1', 'WEEK 2', 'WEEK 3', 'WEEK 4'];

  // Monthly growth bar data (two bars per month: lighter teal, darker teal)
  final monthlyLabels = ['MAR', 'APR', 'MAY', 'JUN', 'JUL'];
  final monthlyValuesA = [4.0, 5.0, 4.5, 6.0, 5.5];
  final monthlyValuesB = [3.0, 4.0, 4.0, 5.0, 5.0];

  @override
  void onInit() {
    _bootstrap();
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

  void goBack() => Get.back();

  void openCalendar() {
    // TODO: date range picker
  }

  void recordPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

}