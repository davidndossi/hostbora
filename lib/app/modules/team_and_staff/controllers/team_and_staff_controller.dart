import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class TeamAndStaffController extends BaseController {
  TeamAndStaffController()
      : _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final RentStaffLocalDataSource _staffLocal;
  final AppRepository _repository;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  /// Loaded from [RentStaffLocalDataSource]; task counts from remote tasks API when available.
  final staffList = <StaffMember>[].obs;
  final loadingStaff = true.obs;

  List<StaffMember> get filteredStaff {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return staffList;
    return staffList
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.role.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadStaff();
  }

  /// Reload staff rows and merge task counts (due today, incomplete).
  Future<void> loadStaff() async {
    loadingStaff.value = true;
    try {
      if (Get.isRegistered<RemoteAccountSyncService>()) {
        await Get.find<RemoteAccountSyncService>().syncStaffFromRemote();
      }
      final rows = await _staffLocal.getAllNewestFirst();
      final tasksDueToday = await _tasksDueTodayCountsByAssigneeLower();
      final members = rows.map((r) {
        final name = r.name.trim();
        final tasksToday = _taskCountForStaffName(tasksDueToday, name);
        return StaffMember(
          id: r.id.toString(),
          name: name.isEmpty ? '—' : name,
          role: r.jobTitle.trim().isEmpty ? 'Staff' : r.jobTitle.trim(),
          tasksToday: tasksToday,
          isHighTaskCount: tasksToday >= 4,
          isOnDuty: true,
          avatarUrl: '',
        );
      }).toList();
      staffList.assignAll(members);
    } catch (_) {
      staffList.clear();
    } finally {
      loadingStaff.value = false;
    }
  }

  /// Incomplete tasks whose due date is today (local calendar), keyed by assignee lower-case.
  Future<Map<String, int>> _tasksDueTodayCountsByAssigneeLower() async {
    final out = <String, int>{};
    try {
      final res = await _repository.getTasks();
      if (res.responseCode != '0' || res.data == null) return out;
      final maps = _extractTaskMaps(res.data);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final m in maps) {
        final assignee =
            (m['assignee'] ?? m['assignedTo'] ?? '').toString().trim();
        if (assignee.isEmpty) continue;
        final lower = assignee.toLowerCase();
        if (lower == 'unassigned') continue;

        final dueStr = m['dueDate'] as String?;
        if (dueStr == null || dueStr.isEmpty) continue;
        final due = DateTime.tryParse(dueStr);
        if (due == null) continue;
        final dueDay = DateTime(due.year, due.month, due.day);
        if (dueDay != today) continue;

        final completed = m['completed'] as bool? ?? false;
        final statusStr = (m['status'] as String?)?.toUpperCase();
        if (completed || statusStr == 'COMPLETED') continue;

        out[lower] = (out[lower] ?? 0) + 1;
      }
    } catch (_) {}
    return out;
  }

  static List<Map<String, dynamic>> _extractTaskMaps(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      final tasks = raw['tasks'];
      if (tasks is List) {
        return tasks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final content = raw['content'];
      if (content is List) {
        return content
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  static int _taskCountForStaffName(
    Map<String, int> countsByAssigneeLower,
    String staffName,
  ) {
    final s = staffName.trim().toLowerCase();
    if (s.isEmpty) return 0;
    if (countsByAssigneeLower.containsKey(s)) {
      return countsByAssigneeLower[s]!;
    }
    final parts = s.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      final first = parts.first;
      if (countsByAssigneeLower.containsKey(first)) {
        return countsByAssigneeLower[first]!;
      }
    }
    for (final e in countsByAssigneeLower.entries) {
      if (e.key.contains(s) || s.contains(e.key)) return e.value;
    }
    return 0;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void addStaff() {
    final f = Get.toNamed(Routes.RENT_STAFF_MANAGEMENT);
    if (f != null) f.then((_) => loadStaff());
  }

  void messageStaff(StaffMember member) {
    // TODO: open chat with staff
  }

  void editStaff(StaffMember member) {
    final f = Get.toNamed(
      Routes.RENT_STAFF_MANAGEMENT,
      arguments: {'staffId': member.id},
    );
    if (f != null) f.then((_) => loadStaff());
  }

  void openStaffDetail(StaffMember member) {
    final f = Get.toNamed(Routes.STAFF_DETAIL, arguments: member);
    if (f != null) f.then((_) => loadStaff());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  final int tasksToday;
  final bool isHighTaskCount;
  final bool isOnDuty;
  final String avatarUrl;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.tasksToday,
    required this.isHighTaskCount,
    required this.isOnDuty,
    required this.avatarUrl,
  });
}
