import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../team_and_staff/controllers/team_and_staff_controller.dart';

class StaffDetailController extends BaseController {
  StaffDetailController()
      : _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final RentStaffLocalDataSource _staffLocal;
  final AppRepository _repository;

  late final StaffMember member;

  final loading = true.obs;
  final displayName = ''.obs;
  final role = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final payLine = ''.obs;
  final joinedLabel = ''.obs;

  final totalTasks = 0.obs;
  final recentTasks = <RecentTask>[].obs;
  final assignedProperties = <AssignedProperty>[].obs;

  bool get hasEmail => email.value.trim().isNotEmpty;
  bool get hasPhone => phone.value.trim().isNotEmpty;
  bool get hasPayInfo => payLine.value.trim().isNotEmpty && payLine.value != '—';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is StaffMember) {
      member = args;
    } else {
      member = StaffMember(
        id: '',
        name: 'Unknown',
        role: 'Staff',
        tasksToday: 0,
        isHighTaskCount: false,
        isOnDuty: false,
        avatarUrl: '',
      );
    }
    displayName.value = member.name;
    role.value = member.role;
    loadDetail();
  }

  Future<void> loadDetail() async {
    loading.value = true;
    try {
      final id = int.tryParse(member.id);
      if (id != null) {
        final record = await _staffLocal.getById(id);
        if (record != null) {
          final name = record.name.trim();
          if (name.isNotEmpty) displayName.value = name;
          final job = record.jobTitle.trim();
          role.value = job.isEmpty ? member.role : job;
          payLine.value = record.displayAmountLine;
          joinedLabel.value = _formatJoined(record.createdAtMs);
        }
      } else if (member.id.isEmpty) {
        joinedLabel.value = '';
      }
      await _loadTasksForMember();
      assignedProperties.clear();
    } catch (_) {
      recentTasks.clear();
      assignedProperties.clear();
      totalTasks.value = 0;
    } finally {
      loading.value = false;
    }
  }

  String _formatJoined(int createdAtMs) {
    if (createdAtMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _loadTasksForMember() async {
    totalTasks.value = 0;
    recentTasks.clear();
    final staffName = displayName.value.trim();
    if (staffName.isEmpty) return;

    try {
      final res = await _repository.getTasks();
      if (res.responseCode != '0' || res.data == null) return;
      final maps = _extractTaskMaps(res.data);
      final matched = <Map<String, dynamic>>[];
      for (final m in maps) {
        final assignee =
            (m['assignee'] ?? m['assignedTo'] ?? '').toString().trim();
        if (_assigneeMatchesStaff(assignee, staffName)) {
          matched.add(m);
        }
      }
      totalTasks.value = matched.length;

      matched.sort((a, b) {
        final aDue = DateTime.tryParse(a['dueDate'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDue = DateTime.tryParse(b['dueDate'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDue.compareTo(aDue);
      });

      for (final m in matched.take(5)) {
        final title = (m['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final completed = m['completed'] as bool? ?? false;
        final statusStr = (m['status'] as String?)?.toUpperCase();
        final isDone = completed || statusStr == 'COMPLETED';
        final when = _taskWhenLabel(m, isDone);
        recentTasks.add(RecentTask(title: title, completedAt: when));
      }
    } catch (_) {}
  }

  String _taskWhenLabel(Map<String, dynamic> m, bool isDone) {
    if (isDone) {
      final at = m['completedAt'] as String?;
      if (at != null && at.isNotEmpty) {
        final dt = DateTime.tryParse(at);
        if (dt != null) return _shortDate(dt);
      }
      return appLocalization.staffDetailTaskCompleted;
    }
    final dueStr = m['dueDate'] as String?;
    if (dueStr != null && dueStr.isNotEmpty) {
      final dt = DateTime.tryParse(dueStr);
      if (dt != null) {
        return '${appLocalization.staffDetailTaskDue} ${_shortDate(dt)}';
      }
    }
    return appLocalization.staffDetailTaskPending;
  }

  static String _shortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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

  static bool _assigneeMatchesStaff(String assignee, String staffName) {
    final a = assignee.trim().toLowerCase();
    final s = staffName.trim().toLowerCase();
    if (a.isEmpty || s.isEmpty || a == 'unassigned') return false;
    if (a == s) return true;
    final parts = s.split(RegExp(r'\s+'));
    if (parts.isNotEmpty && a == parts.first) return true;
    return a.contains(s) || s.contains(a);
  }

  Future<void> openEmail() async {
    final value = email.value.trim();
    if (value.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: value);
    if (!await canLaunchUrl(uri)) {
      showErrorMessage(appLocalization.staffDetailCannotOpenEmail);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openPhone() async {
    final raw = phone.value.trim();
    if (raw.isEmpty) return;
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits.isEmpty ? raw : digits);
    if (!await canLaunchUrl(uri)) {
      showErrorMessage(appLocalization.staffDetailCannotOpenPhone);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void manageProperties() {
    showErrorMessage(appLocalization.staffDetailAssignFromListing);
  }

  void assignNewTask() {
    Get.toNamed(
      Routes.MAINTENANCE_TASKS,
      arguments: {'assigneeHint': displayName.value},
    );
  }

  Future<void> removeFromTeam() async {
    final id = int.tryParse(member.id);
    if (id == null) {
      showErrorMessage(appLocalization.staffDetailCannotRemove);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.staffDetailConfirmRemoveTitle),
        content: Text(
          appLocalization.staffDetailConfirmRemoveBody(displayName.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              appLocalization.staffDetailRemoveConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    showLoading();
    try {
      await _staffLocal.deleteById(id);
      hideLoading();
      showSuccessMessage(appLocalization.staffDetailRemovedSuccess);
      Get.back(result: true);
    } catch (e) {
      hideLoading();
      showErrorMessage(e.toString());
    }
  }
}

class AssignedProperty {
  final String title;
  final String location;
  final String imageUrl;

  AssignedProperty({
    required this.title,
    required this.location,
    required this.imageUrl,
  });
}

class RecentTask {
  final String title;
  final String completedAt;

  RecentTask({required this.title, required this.completedAt});
}
