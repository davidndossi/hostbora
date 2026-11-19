import 'dart:convert';

import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import 'assigned_task_inbox.dart';
import 'model/maintenance_task.dart';

/// Keeps staff assignment / completion when GET /api/tasks omits or lags them.
class TaskAssignmentStore {
  TaskAssignmentStore._();

  static PreferenceManager get _prefs => Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  static Future<void> remember(MaintenanceTask task) async {
    if (task.id.isEmpty) return;
    try {
      final all = await _readAll();
      all[task.id] = {
        if (_hasAssignee(task.assignee)) 'assignee': task.assignee.trim(),
        'status': task.status.name,
        'isCompleted': task.isCompleted,
        if (task.completedAt != null)
          'completedAtMs': task.completedAt!.millisecondsSinceEpoch,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };
      await _prefs.setString(
        PreferenceManager.keyTaskAssignmentOverrides,
        jsonEncode(all),
      );
      await AssignedTaskInbox.save(task);
    } catch (_) {}
  }

  /// Assignee remembered for [taskId] when the task API omits it.
  static Future<String> assigneeFor(String taskId) async {
    if (taskId.trim().isEmpty) return '';
    try {
      final patch = (await _readAll())[taskId];
      if (patch is! Map) return '';
      final name = patch['assignee']?.toString().trim() ?? '';
      return _hasAssignee(name) ? name : '';
    } catch (_) {
      return '';
    }
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
      final patch = stored[task.id];
      final patchMap = patch is Map ? Map<String, dynamic>.from(patch) : null;

      var merged = task;

      // Restore assignee when the list payload omits it.
      if (!_hasAssignee(merged.assignee)) {
        if (mem != null && _hasAssignee(mem.assignee)) {
          merged = merged.copyWith(assignee: mem.assignee);
        } else {
          final storedAssignee = patchMap?['assignee']?.toString() ?? '';
          if (_hasAssignee(storedAssignee)) {
            merged = merged.copyWith(assignee: storedAssignee);
          }
        }
      }

      // A newer server edit replaces a stamped phone edit. An undated phone
      // completion is still kept so a lagging GET cannot undo it.
      final localMs = (patchMap?['updatedAtMs'] as num?)?.toInt() ?? 0;
      final serverWins = merged.remoteUpdatedAtMs > 0 &&
          localMs > 0 &&
          merged.remoteUpdatedAtMs > localMs;
      if (!serverWins &&
          merged.status != TaskStatus.completed &&
          !merged.isCompleted) {
        final memCompleted = mem != null &&
            (mem.status == TaskStatus.completed || mem.isCompleted);
        final patchStatus = _statusFromName(patchMap?['status']?.toString());
        final patchCompleted = patchMap?['isCompleted'] == true ||
            patchMap?['isCompleted']?.toString() == 'true' ||
            patchStatus == TaskStatus.completed;
        if (memCompleted || patchCompleted) {
          DateTime? completedAt = mem?.completedAt;
          final ms = patchMap?['completedAtMs'];
          if (completedAt == null && ms is num) {
            completedAt =
                DateTime.fromMillisecondsSinceEpoch(ms.toInt());
          }
          merged = merged.copyWith(
            status: TaskStatus.completed,
            isCompleted: true,
            completedAt: completedAt ?? DateTime.now(),
          );
        } else if (mem != null &&
            !_hasAssignee(task.assignee) &&
            mem.status != TaskStatus.pending) {
          // Keep in-progress from memory when assignee was also restored above.
          merged = merged.copyWith(status: mem.status);
        } else if (patchStatus != null &&
            patchStatus != TaskStatus.pending &&
            !_hasAssignee(task.assignee)) {
          merged = merged.copyWith(status: patchStatus);
        }
      }

      return merged;
    }).toList();
  }

  static Future<Map<String, dynamic>> readPatches() => _readAll();

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
