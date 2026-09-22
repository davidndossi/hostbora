import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/access/staff_access.dart';
import '../../../core/base/base_controller.dart';
import '../../../data/model/staff_request.dart';
import '../../rent/staff_management/widgets/staff_access_editor.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../team_and_staff/controllers/team_and_staff_controller.dart';

class StaffDetailController extends BaseController {
  StaffDetailController()
      : _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentStaffLocalDataSource _staffLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  late final StaffMember member;

  final loading = true.obs;
  final displayName = ''.obs;
  final role = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final payLine = ''.obs;
  final joinedLabel = ''.obs;
  final permissionRole = StaffPermissions.roleCleaner.obs;
  final grantedPermissions = StaffPermissions.preset(StaffPermissions.roleCleaner).obs;
  final allPropertiesAccess = true.obs;
  final selectedPropertyRefs = <String>{}.obs;
  final accessProperties = <StaffPropertyOption>[].obs;
  final legacyStaffAccess = false.obs;
  final savingAccess = false.obs;

  String _phone = '';
  double _salary = 0;
  String _salaryFrequency = 'monthly';
  String _notes = '';
  String? _backendId;
  String _propertyRef = '';
  String _propertyName = '';

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
      await _loadAccess();
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

  void applyPermissionRole(String value) {
    permissionRole.value = value;
    grantedPermissions.assignAll(StaffPermissions.preset(value));
    allPropertiesAccess.value = StaffPermissions.defaultAllProperties(value);
    legacyStaffAccess.value = false;
  }

  void togglePermission(String key) {
    if (grantedPermissions.contains(key)) {
      grantedPermissions.remove(key);
    } else {
      grantedPermissions.add(key);
    }
    legacyStaffAccess.value = false;
  }

  void setAllPropertiesAccess(bool value) {
    allPropertiesAccess.value = value;
    legacyStaffAccess.value = false;
  }

  void togglePropertyRef(String ref) {
    if (selectedPropertyRefs.contains(ref)) {
      selectedPropertyRefs.remove(ref);
    } else {
      selectedPropertyRefs.add(ref);
    }
    legacyStaffAccess.value = false;
  }

  Future<void> saveAccess() async {
    final id = _backendId?.trim() ?? '';
    if (id.isEmpty) {
      showErrorMessage(appLocalization.staffDetailCannotRemove);
      return;
    }
    if (!allPropertiesAccess.value && selectedPropertyRefs.isEmpty) {
      showErrorMessage(appLocalization.staffAccessSelectProperty);
      return;
    }
    if (_phone.trim().isEmpty) {
      showErrorMessage(appLocalization.staffDetailCannotOpenPhone);
      return;
    }
    savingAccess.value = true;
    try {
      final request = StaffRequest(
        id: id,
        name: displayName.value,
        role: role.value.trim().isEmpty ? permissionRole.value : role.value,
        salary: _salary,
        salaryFrequency: _salaryFrequency,
        phone: _phone,
        notes: _notes,
        propertyRef: _propertyRef,
        propertyName: _propertyName,
        permissionRole: permissionRole.value,
        permissions: grantedPermissions.toList(),
        allProperties: allPropertiesAccess.value,
        propertyRefs: selectedPropertyRefs.toList(),
      );
      final res = await _repository.updateStaff(id, request.toApiJson());
      if (!res.isSuccess) {
        showErrorMessage(res.message ?? appLocalization.staffDetailCannotRemove);
        return;
      }
      legacyStaffAccess.value = false;
      showSuccessMessage(appLocalization.staffAccessSaved);
    } catch (e) {
      showErrorMessage(appLocalization.staffDetailCannotRemove);
    } finally {
      savingAccess.value = false;
    }
  }

  Future<void> _loadAccess() async {
    try {
      final localId = int.tryParse(member.id);
      if (localId != null) {
        _backendId = await _staffLocal.backendIdForLocal(localId);
      }
    } catch (_) {}
    await _loadProperties();
    await _loadRemoteAccess();
  }

  Future<void> _loadProperties() async {
    try {
      final rows = await Get.find<PropertyLocalDataSource>().fetchAll(userId: '');
      accessProperties.assignAll(
        rows
            .where((row) => row.propertyRef.trim().isNotEmpty)
            .map(
              (row) => StaffPropertyOption(
                ref: row.propertyRef.trim(),
                name: row.propertyName.trim(),
              ),
            ),
      );
    } catch (_) {}
  }

  Future<void> _loadRemoteAccess() async {
    try {
      final res = await _repository.getStaffList();
      if (!res.isSuccess || res.data == null) return;
      final maps = _staffMaps(res.data);
      Map<String, dynamic>? match;
      for (final row in maps) {
        final id = (row['id'] ?? '').toString();
        final rowName = (row['name'] ?? '').toString().trim().toLowerCase();
        if (_backendId != null && id == _backendId) {
          match = row;
          break;
        }
        if (rowName.isNotEmpty && rowName == displayName.value.trim().toLowerCase()) {
          match ??= row;
        }
      }
      if (match == null) return;
      _backendId = (match['id'] ?? _backendId)?.toString();
      _phone = (match['phone'] ?? '').toString();
      _salary = (match['salary'] as num?)?.toDouble() ?? _salary;
      _salaryFrequency = (match['salaryFrequency'] ?? _salaryFrequency).toString();
      _notes = (match['notes'] ?? '').toString();
      _propertyRef = (match['propertyRef'] ?? '').toString();
      _propertyName = (match['propertyName'] ?? '').toString();
      if (_phone.isNotEmpty) phone.value = _phone;
      final legacy = match['legacyAccess'] == true;
      legacyStaffAccess.value = legacy;
      final roleKey = (match['permissionRole'] ?? '').toString();
      permissionRole.value = StaffPermissions.roles.contains(roleKey)
          ? roleKey
          : StaffPermissions.roleCleaner;
      final raw = match['permissions'];
      if (raw is List && raw.isNotEmpty) {
        grantedPermissions.assignAll(raw.map((e) => e.toString()));
      } else if (legacy) {
        grantedPermissions.assignAll(StaffPermissions.all);
      }
      allPropertiesAccess.value = legacy || match['allProperties'] == true;
      selectedPropertyRefs.clear();
      final refs = match['propertyRefs'];
      if (refs is List) {
        selectedPropertyRefs.addAll(
          refs.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
        );
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _staffMaps(dynamic raw) {
    if (raw is Map && raw['staff'] is List) {
      return (raw['staff'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
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

    final snapshot = await _staffLocal.getById(id);
    if (snapshot == null) {
      showErrorMessage(appLocalization.staffDetailRemovedSuccess);
      return;
    }
    final backendStaffId = await _staffLocal.backendIdForLocal(id);

    final apiStaffId = backendStaffId ?? '$id';
    await runDestructiveWithUndo(
      message: appLocalization.staffDetailRemovedSuccess,
      action: () async {
        await _staffLocal.deleteById(id);
        try {
          final res = await _repository.deleteStaff(apiStaffId);
          if (!res.isSuccess) throw Exception(res.message ?? 'API error');
        } catch (_) {
          await _syncQueue.enqueue(
            entityType: 'staff',
            operation: 'delete',
            payloadJson: jsonEncode({'id': apiStaffId}),
            dedupeKey: 'staff:delete:$apiStaffId',
          );
          _syncWorker.runNow();
        }
        Get.back(result: true);
      },
      onUndo: () async {
        await _syncQueue.deleteByDedupeKey('staff:delete:$apiStaffId');
        await _staffLocal.restore(snapshot, backendStaffId: backendStaffId);
      },
    );
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
