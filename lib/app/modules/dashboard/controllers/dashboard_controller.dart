import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/community.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/user_community.dart';
import '../../../data/model/user_profile_request.dart';
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

  void _syncCommunitySearchFromSelection() {
    final name = selectedCommunity.value?.name ?? '';
    communitySearchController.text = name;
  }

  Future<void> _bootstrap() async {
    await getFirebaseToken();
    isLeader(await _preferenceManager.getBool('isLeader'));
    isAdmin(await _preferenceManager.getBool('isAdmin'));
    if (isAdmin.value) isMember(true);
    if (Get.arguments != null) {
      // if (Get.arguments['user'] != null) {}
      //isMember
      if (Get.arguments['isMember'] != null) {
        bool isMember = Get.arguments['isMember'];
        this.isMember(isMember);
      }
    }
    await loadCommunities();
  }

  Future<void> getFirebaseToken() async {
    firebaseToken = await _preferenceManager.getString(PreferenceManager.keyFirebaseToken);
  }

  Future<void> loadCommunities() async {
    try {
      final list = await _preferenceManager.getUserCommunities();
      communities.assignAll(list);
      // filteredCommunities.assignAll(list);

      if (list.isNotEmpty) {
        selectedCommunity(list.first);
        _syncCommunitySearchFromSelection();
        await refreshCommunityData();
      }

      ever(communitySearch, (_) => applyCommunityFilter());
      //ever(selectedCommunity, (_) => _syncCommunitySearchFromSelection());
      ever(memberSearch, (_) => applyMemberFilter());
      ever(memberRoleFilter, (_) => applyMemberFilter());
      ever(memberStatusFilter, (_) => applyMemberFilter());
    } catch (e) {
      // If storage is empty or not set yet, just keep lists empty.
    }
  }

  void applyCommunityFilter() {
    // cancel previous timer if still active
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // debounce for 300ms
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = communitySearch.value.trim().toLowerCase();
      if (isAdmin.value) {
        if (q.isNotEmpty && q.length > 3) {
          getCommunities(q);
        }
      } else {
        if (q.isEmpty) {
          filteredCommunities.assignAll(communities);
          return;
        }
        filteredCommunities.assignAll(
          communities
              .where((c) => (c.name ?? '').toLowerCase().contains(q))
              .toList(),
        );
        showList(true);
      }
    });
  }

  Future<void> onSelectCommunity(Community? community) async {
    selectedCommunity(community);
    showList(false);
    _syncCommunitySearchFromSelection();
    await refreshCommunityData();
  }

  Future<void> refreshCommunityData() async {
    final communityId = selectedCommunity.value?.id;
    if (communityId == null || communityId.isEmpty) return;

    isLoading(true);

    final user = await _preferenceManager.getUser();
    final request = UserProfileRequest(
      communityId: communityId,
      userId: user.id,
    );

    try {
      final results = await Future.wait([
        _repository.getActiveMembers(request),
        _repository.getDeceasedMembers(request),
        _repository.getActiveMaleMembers(request),
        _repository.getActiveFemaleMembers(request),
        _repository.getDeceasedMaleMembers(request),
        _repository.getDeceasedFemaleMembers(request),
        _repository.getCommunityLeaders(request),
        _repository.getCommunityMembers(request),
      ]);

      final active = _asInt(results[0]);
      final deceased = _asInt(results[1]);
      final activeMale = _asInt(results[2]);
      final activeFemale = _asInt(results[3]);
      final deceasedMale = _asInt(results[4]);
      final deceasedFemale = _asInt(results[5]);
      final leadersCount = _asListLen(results[6]);

      stats.assignAll([
        {'title': 'Active Members', 'count': active, 'icon': Icons.people, 'color': Colors.blue},
        {'title': 'Deceased Members', 'count': deceased, 'icon': Icons.person_off, 'color': Colors.red},
        {'title': 'Male Active Members', 'count': activeMale, 'icon': Icons.male, 'color': Colors.blueAccent},
        {'title': 'Female Active Members', 'count': activeFemale, 'icon': Icons.female, 'color': Colors.purple},
        {'title': 'Male Deceased Members', 'count': deceasedMale, 'icon': Icons.male, 'color': Colors.redAccent},
        {'title': 'Female Deceased Members', 'count': deceasedFemale, 'icon': Icons.female, 'color': Colors.pink},
        {'title': 'Leaders', 'count': leadersCount, 'icon': Icons.star, 'color': Colors.orange},
      ]);

      final memberList = _asUserCommunityList(results[7]);
      members.assignAll(memberList);
      applyMemberFilter();
    } catch (e) {
      // Keep the last known data; show a visible error to user.
      showErrorMessage('Failed to load community dashboard data.');
    } finally {
      isLoading(false);
    }
  }

  void applyMemberFilter() {
    final q = memberSearch.value.trim().toLowerCase();

    getCommunityMembers(q);
  }

  int _asInt(GeneralResponse res) {
    final d = res.data;
    if (d is int) return d;
    if (d is num) return d.toInt();
    if (d is String) return int.tryParse(d) ?? 0;
    return 0;
  }

  int _asListLen(GeneralResponse res) {
    final d = res.data;
    if (d is List) return d.length;
    return 0;
  }

  List<UserCommunity> _asUserCommunityList(GeneralResponse res) {
    final d = res.data;
    if (d is List) {
      return d
          .map((e) => UserCommunity.fromJson(e as dynamic))
          .toList();
    }
    return [];
  }

  void getCommunityMembers(String searchValue) {
    UserProfileRequest request = UserProfileRequest(
      communityId: selectedCommunity.value?.id
    );
    callDataService(
      _repository.getCommunityMembers(request),
      onSuccess: _handleGetCommunityMembersSuccess,
      onError: _handleQueryResponseError
    );
  }

  void _handleQueryResponseError(Exception e) {
    isLoading(false);
  }

  void _handleGetCommunityMembersSuccess(GeneralResponse res) async {
    final List<UserCommunity> userCommunities = (res.data as List).map((e) => UserCommunity.fromJson(e)).toList();
    members.assignAll(userCommunities);

    final q = memberSearch.value.trim().toLowerCase();
    final role = memberRoleFilter.value.trim().toLowerCase();
    final status = memberStatusFilter.value.trim().toLowerCase();

    filteredMembers.assignAll(
      members.where((m) {
        final name = (m.name ?? '').toLowerCase();
        final mRole = (m.role ?? '').toLowerCase();
        final mStatus = (m.status ?? '').toLowerCase();

        final matchesQuery = q.isEmpty || name.contains(q);
        final matchesRole = role.isEmpty || mRole == role;
        final matchesStatus = status.isEmpty || mStatus == status;

        return matchesQuery && matchesRole && matchesStatus;
      }).toList(),
    );
  }

  void _handleGetCommunitiesSuccess(GeneralResponse res) async {
    final List<Community> list = (res.data as List).map((e) => Community.fromJson(e)).toList();
    filteredCommunities.assignAll(list);
    showList(true);
  }

  void getCommunities(String searchValue) {
    callDataService(
      _repository.getCommunities(searchValue),
      onSuccess: _handleGetCommunitiesSuccess,
      onError: _handleQueryResponseError
    );
  }

  void goBack() => Get.back();

  void openCalendar() {
    // TODO: date range picker
  }

  void recordPayment() => Get.toNamed(Routes.RECORD_PAYMENT);

  void selectIncome() => isIncomeSelected.value = true;
  void selectExpenses() => isIncomeSelected.value = false;

}