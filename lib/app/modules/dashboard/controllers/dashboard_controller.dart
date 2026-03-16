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

  final isLoading = true.obs;
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

  // Metric card data (Income view) – from server
  final totalRevenue = 'TZS 0'.obs;
  final totalRevenueChange = '+0%'.obs;
  final totalRevenueUp = true.obs;

  final avgDailyRate = 'TZS 0'.obs;
  final avgDailyRateChange = '+0%'.obs;
  final avgDailyRateUp = true.obs;

  final netProfit = 'TZS 0'.obs;
  final netProfitChange = '+0%'.obs;
  final netProfitUp = true.obs;

  // Performance trends (income = revenue) – from server
  final currentTrendValues = <double>[0, 0, 0, 0].obs;
  final previousTrendValues = <double>[0, 0, 0, 0].obs;
  // Performance trends (expenses) – from server
  final currentExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  final previousExpenseTrendValues = <double>[0, 0, 0, 0].obs;
  static const trendLabels = ['WEEK 1', 'WEEK 2', 'WEEK 3', 'WEEK 4'];

  // Monthly: A = revenue, B = expenses – from server
  final monthlyLabels = <String>['MAR', 'APR', 'MAY', 'JUN', 'JUL'].obs;
  final monthlyValuesA = <double>[0, 0, 0, 0, 0].obs;
  final monthlyValuesB = <double>[0, 0, 0, 0, 0].obs;

  // Expense metrics – from server
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
      final res = await _repository.getDashboard();
      if (res.responseCode == '0' && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        totalRevenue.value = _string(data['totalRevenue']) ?? 'TZS 0';
        totalRevenueChange.value = _string(data['totalRevenueChange']) ?? '+0%';
        totalRevenueUp.value = data['totalRevenueUp'] == true;
        avgDailyRate.value = _string(data['avgDailyRate']) ?? 'TZS 0';
        avgDailyRateChange.value = _string(data['avgDailyRateChange']) ?? '+0%';
        avgDailyRateUp.value = data['avgDailyRateUp'] == true;
        netProfit.value = _string(data['netProfit']) ?? 'TZS 0';
        netProfitChange.value = _string(data['netProfitChange']) ?? '+0%';
        netProfitUp.value = data['netProfitUp'] == true;
        final cur = data['currentTrendValues'];
        if (cur is List) {
          currentTrendValues.assignAll((cur as List).map((e) => (e is num) ? e.toDouble() : 0.0).take(4).toList());
        }
        final prev = data['previousTrendValues'];
        if (prev is List) {
          previousTrendValues.assignAll((prev as List).map((e) => (e is num) ? e.toDouble() : 0.0).take(4).toList());
        }
        final labels = data['monthlyLabels'];
        if (labels is List) {
          monthlyLabels.assignAll((labels as List).map((e) => e?.toString() ?? '').toList());
        }
        final ma = data['monthlyValuesA'];
        if (ma is List) {
          monthlyValuesA.assignAll((ma as List).map((e) => (e is num) ? e.toDouble() : 0.0).toList());
        }
        final mb = data['monthlyValuesB'];
        if (mb is List) {
          monthlyValuesB.assignAll((mb as List).map((e) => (e is num) ? e.toDouble() : 0.0).toList());
        }
        totalExpenses.value = _string(data['totalExpenses']) ?? 'TZS 0';
        totalExpensesChange.value = _string(data['totalExpensesChange']) ?? '+0%';
        totalExpensesUp.value = data['totalExpensesUp'] == true;
        avgDailyExpense.value = _string(data['avgDailyExpense']) ?? 'TZS 0';
        avgDailyExpenseChange.value = _string(data['avgDailyExpenseChange']) ?? '+0%';
        avgDailyExpenseUp.value = data['avgDailyExpenseUp'] == true;
        final curExp = data['currentExpenseTrendValues'];
        if (curExp is List) {
          currentExpenseTrendValues.assignAll((curExp as List).map((e) => (e is num) ? e.toDouble() : 0.0).take(4).toList());
        }
        final prevExp = data['previousExpenseTrendValues'];
        if (prevExp is List) {
          previousExpenseTrendValues.assignAll((prevExp as List).map((e) => (e is num) ? e.toDouble() : 0.0).take(4).toList());
        }
      }
    } catch (_) {
      // keep default/placeholder values
    } finally {
      isLoading.value = false;
    }
  }

  String? _string(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  void goBack() => Get.back();

  void recordPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void addExpense() => Get.toNamed(Routes.ADD_EXPENSE);

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

}