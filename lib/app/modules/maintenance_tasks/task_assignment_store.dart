import 'dart:convert';

import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import 'model/maintenance_task.dart';

/// Keeps staff assignment / status when GET /api/tasks omits them.
class TaskAssignmentStore {
  TaskAssignmentStore._();

  static PreferenceManager get _prefs => Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  static Future<void> remember(MaintenanceTask task) async {
    if (task.id.isEmpty) return;
    if (!_hasAssignee(task.assignee)) return;
    try {
      final all = await _readAll();
      all[task.id] = {
        'assignee': task.assignee.trim(),
        'status': task.status.name,
      };
      await _prefs.setString(
        PreferenceManager.keyTaskAssignmentOverrides,
        jsonEncode(all),
      );
    } catch (_) {}
  }

  static Future<List<MaintenanceTask>> applyAll(
    List<MaintenanceTask> remote, {
    List<MaintenanceTask> memory = const [],
  }) async {
    final previous = {
      for (final t in memory)
        if (t.id.isNotEmpty) t.id: t,
    };
    Map<String, dynamic> stored = const {};
    try {
      stored = await _readAll();
    } catch (_) {}

    return remote.map((task) {
      final mem = previous[task.id];
      if (_hasAssignee(task.assignee)) return task;

      if (mem != null && _hasAssignee(mem.assignee)) {
        return task.copyWith(assignee: mem.assignee, status: mem.status);
      }

      final patch = stored[task.id];
      if (patch is Map) {
        final assignee = patch['assignee']?.toString() ?? '';
        if (_hasAssignee(assignee)) {
          return task.copyWith(
            assignee: assignee,
            status: _statusFromName(patch['status']?.toString()) ?? task.status,
          );
        }
      }
      return task;
    }).toList();
  }

  static Future<Map<String, dynamic>> _readAll() async {
    final raw = await _prefs.getString(
      PreferenceManager.keyTaskAssignmentOverrides,
      defaultValue: '',
    );
    if (raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static bool _hasAssignee(String value) {
    final s = value.trim().toLowerCase();
    return s.isNotEmpty &&
        s != 'unassigned' &&
        s != '—' &&
        s != '-' &&
        s != 'null';
  }

  static TaskStatus? _statusFromName(String? name) {
    switch (name) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'pending':
        return TaskStatus.pending;
      default:
        return null;
    }
  }
}
