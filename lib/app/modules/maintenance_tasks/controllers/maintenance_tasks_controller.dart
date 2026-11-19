import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/synced_entity_store.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../assigned_task_inbox.dart';
import '../task_assignment_store.dart';
import '../../../routes/app_pages.dart';
import '../model/maintenance_task.dart';

enum TaskFilter { all, pending, inProgress, completed }

class MaintenanceTasksController extends BaseController {
  final AppRepository _repository =
      Get.find<AppRepository>(tag: (AppRepository).toString());
  final OfflineSyncQueueLocalDataSource _syncQueue =
      Get.find<OfflineSyncQueueLocalDataSource>();
  final OfflineSyncWorkerService _syncWorker =
      Get.find<OfflineSyncWorkerService>();

  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;
  /// Full unfiltered set — counters always read from here.
  final RxList<MaintenanceTask> allTasks = <MaintenanceTask>[].obs;
  /// Full-screen skeleton only on first empty load.
  final loading = false.obs;
  /// Thin progress while refreshing with existing rows on screen.
  final refreshing = false.obs;

  static const _remoteTimeout = Duration(seconds: 10);

  /// Tasks just created on this device. Kept on screen until the server list
  /// returns the same row.
  final _optimisticTaskIds = <String>{};

  /// Visible rows for the selected tab.
  List<MaintenanceTask> get visibleTasks {
    switch (selectedFilter.value) {
      case TaskFilter.pending:
        return allTasks.where((t) => t.status == TaskStatus.pending).toList();
      case TaskFilter.inProgress:
        return allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return allTasks.where((t) => t.status == TaskStatus.completed).toList();
      case TaskFilter.all:
        return allTasks.toList();
    }
  }

  int get countAll => allTasks.length;
  int get countPending =>
      allTasks.where((t) => t.status == TaskStatus.pending).length;
  int get countInProgress =>
      allTasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get countCompleted =>
      allTasks.where((t) => t.status == TaskStatus.completed).length;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  /// Always loads every task so tab counters stay correct.
  Future<void> loadTasks() async {
    final showBlocking = allTasks.isEmpty;
    if (showBlocking) {
      loading.value = true;
    } else {
      refreshing.value = true;
    }
    final previous = allTasks.toList();
    try {
      final res = await _repository.getTasks().timeout(_remoteTimeout);
      if (!res.isSuccess || res.data == null) {
        if (allTasks.isEmpty) await _loadCachedTasks();
        return;
      }
      final raw = res.data!;
      List<dynamic> list = [];
      if (raw is Map && raw['tasks'] is List) {
        list = raw['tasks'] as List;
      } else if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['content'] is List) {
        list = raw['content'] as List;
      }
      final items = list
          .whereType<Map>()
          .map((e) => MaintenanceTask.fromApiMap(Map<String, dynamic>.from(e)))
          .where((t) => t.id.isNotEmpty)
          .toList();
      final mirror = SyncedEntityStore();
      for (final raw in list.whereType<Map>()) {
        final map = Map<String, dynamic>.from(raw);
        final task = MaintenanceTask.fromApiMap(map);
        if (task.id.isEmpty) continue;
        await mirror.saveRemoteIfNotOlder(
          entityType: SyncedEntityStore.taskType,
          entityKey: task.id,
          payload: map,
          remoteUpdatedAtMs: task.remoteUpdatedAtMs,
        );
      }
      final remote = await TaskAssignmentStore.applyAll(items, memory: previous);
      final assignedToMe = await AssignedTaskInbox.forCurrentUser();
      allTasks.assignAll(
        _withOptimisticTasks(_mergeAssigned(remote, assignedToMe), previous),
      );
    } catch (_) {
      // Keep the current list so a failed refresh does not wipe assignments.
      if (allTasks.isEmpty) {
        await _loadCachedTasks();
      }
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  Future<void> _loadCachedTasks() async {
    try {
      final cached = await SyncedEntityStore().load(SyncedEntityStore.taskType);
      final items = cached
          .map((row) => MaintenanceTask.fromApiMap(row.payload))
          .where((task) => task.id.isNotEmpty)
          .toList();
      if (items.isEmpty) return;
      final merged = await TaskAssignmentStore.applyAll(items);
      allTasks.assignAll(merged);
    } catch (_) {}
  }

  void setFilter(TaskFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
  }

  Future<void> toggleComplete(MaintenanceTask task) async {
    final idx = allTasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    final now = DateTime.now();
    final completing = !task.isCompleted;
    final updated = MaintenanceTask(
      id: task.id,
      title: task.title,
      assignee: task.assignee,
      description: task.description,
      priority: task.priority,
      status: completing ? TaskStatus.completed : TaskStatus.pending,
      dueDate: task.dueDate,
      isCompleted: completing,
      completedAt: completing ? now : null,
    );
    allTasks[idx] = updated;
    // Persist locally so a later GET that still returns PENDING does not wipe it.
    await TaskAssignmentStore.remember(updated);
    final request = updated.toUpdateRequest();
    try {
      final res = await _repository.updateTask(task.id, request);
      if (!res.isSuccess) {
        await _queueTaskUpdate(task.id, request);
      }
    } catch (_) {
      await _queueTaskUpdate(task.id, request);
    }
  }

  Future<void> _queueTaskUpdate(String taskId, AddTaskRequest request) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'task',
        operation: 'update',
        payloadJson: jsonEncode({
          'taskId': taskId,
          ...request.toJson(),
        }),
        dedupeKey: 'task:update:$taskId',
      );
      _syncWorker.runNow();
    } catch (_) {}
  }

  Future<void> completeTaskFromSwipe(MaintenanceTask task) async {
    if (task.isCompleted) return;
    await toggleComplete(task);
    hapticPrimaryConfirm();
  }

  Future<void> snoozeTask(MaintenanceTask task, {int days = 1}) async {
    final base = task.dueDate ?? DateTime.now();
    final newDue = DateTime(base.year, base.month, base.day)
        .add(Duration(days: days));
    final dueIso = DateFormat('yyyy-MM-dd').format(newDue);
    final request = task.toUpdateRequest(dueDateOverride: dueIso);
    try {
      final res = await _repository.updateTask(task.id, request);
      if (res.isSuccess) {
        _replaceTask(task.copyWith(dueDate: newDue));
        hapticPrimaryConfirm();
        showSuccessMessage(
          'Due ${DateFormat('MMM d, yyyy').format(newDue)}',
        );
        return;
      }
      showErrorMessage(res.message ?? 'Could not snooze task');
    } catch (e) {
      _replaceTask(task.copyWith(dueDate: newDue));
      showSuccessMessage('Due date moved locally to $dueIso');
    }
  }

  void addTask() async {
    final result = await Get.toNamed(Routes.ADD_TASK);
    if (result == null) return;
    applyAddTaskResult(result);
    await loadTasks();
  }

  /// Puts a task saved on the Add Task screen at the top of the list at once.
  void applyAddTaskResult(dynamic result) {
    if (result is! Map) return;
    final task = MaintenanceTask.fromArguments(
      Map<String, dynamic>.from(result),
    );
    if (task.id.isEmpty || task.title.trim().isEmpty) return;
    _optimisticTaskIds.add(task.id);
    final idx = allTasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) allTasks.removeAt(idx);
    allTasks.insert(0, task);
    TaskAssignmentStore.remember(task);
    _showFilterThatIncludes(task);
  }

  void _showFilterThatIncludes(MaintenanceTask task) {
    final visible = switch (selectedFilter.value) {
      TaskFilter.pending => task.status == TaskStatus.pending,
      TaskFilter.inProgress => task.status == TaskStatus.inProgress,
      TaskFilter.completed => task.status == TaskStatus.completed,
      TaskFilter.all => true,
    };
    if (!visible) selectedFilter.value = TaskFilter.all;
  }

  List<MaintenanceTask> _mergeAssigned(
    List<MaintenanceTask> remote,
    List<MaintenanceTask> assignedToMe,
  ) {
    if (assignedToMe.isEmpty) return remote;
    final seen = <String>{for (final task in remote) task.id};
    final merged = List<MaintenanceTask>.from(remote);
    for (final task in assignedToMe) {
      if (task.id.isEmpty || seen.contains(task.id)) continue;
      merged.insert(0, task);
      seen.add(task.id);
    }
    return merged;
  }

  List<MaintenanceTask> _withOptimisticTasks(
    List<MaintenanceTask> remote,
    List<MaintenanceTask> previous,
  ) {
    if (_optimisticTaskIds.isEmpty) return remote;
    final remoteIds = remote.map((t) => t.id).toSet();
    final previousIds = previous.map((t) => t.id).toSet();
    final known = <String, MaintenanceTask>{
      for (final task in previous) task.id: task,
      for (final task in allTasks) task.id: task,
    };
    final kept = <MaintenanceTask>[];
    for (final id in _optimisticTaskIds.toList()) {
      if (remoteIds.contains(id)) {
        _optimisticTaskIds.remove(id);
        continue;
      }
      final local = known[id];
      if (local == null) {
        _optimisticTaskIds.remove(id);
        continue;
      }
      final echoed = remote.any(
        (row) =>
            !previousIds.contains(row.id) && _sameCreatedTask(row, local),
      );
      if (echoed) {
        _optimisticTaskIds.remove(id);
        continue;
      }
      kept.add(local);
    }
    if (kept.isEmpty) return remote;
    return [...kept, ...remote];
  }

  bool _sameCreatedTask(MaintenanceTask remote, MaintenanceTask local) {
    if (remote.title.trim().toLowerCase() != local.title.trim().toLowerCase()) {
      return false;
    }
    final a = remote.dueDate;
    final b = local.dueDate;
    if (a == null || b == null) return true;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void openTaskDetail(MaintenanceTask task) {
    Get.toNamed(Routes.TASK_DETAIL, arguments: task.toArguments())
        ?.then((result) async {
      MaintenanceTask? localUpdate;
      if (result is Map) {
        localUpdate = MaintenanceTask.fromArguments(
          Map<String, dynamic>.from(result),
        );
        _mergeTaskIntoList(localUpdate);
      }
      await loadTasks();
      if (localUpdate != null) {
        _mergeTaskIntoList(localUpdate);
      }
    });
  }

  void _replaceTask(MaintenanceTask updated) {
    final idx = allTasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    allTasks[idx] = updated;
  }

  void _mergeTaskIntoList(MaintenanceTask updated) {
    if (updated.id.isEmpty) return;
    final idx = allTasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final current = allTasks[idx];
    final assignee = _isUnassigned(updated.assignee)
        ? current.assignee
        : updated.assignee;
    allTasks[idx] = MaintenanceTask(
      id: current.id,
      title: updated.title.isNotEmpty ? updated.title : current.title,
      assignee: assignee,
      description: updated.description,
      priority: updated.priority,
      status: updated.status,
      dueDate: updated.dueDate,
      isCompleted: updated.isCompleted,
      completedAt: updated.completedAt,
    );
    TaskAssignmentStore.remember(allTasks[idx]);
  }

  static bool _isUnassigned(String value) {
    final s = value.trim().toLowerCase();
    return s.isEmpty || s == 'unassigned' || s == '—' || s == '-';
  }
}
