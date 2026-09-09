import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/repository/app_repository.dart';
import '../task_assignment_store.dart';
import '../../../routes/app_pages.dart';
import '../model/maintenance_task.dart';

enum TaskFilter { all, pending, inProgress, completed }

class MaintenanceTasksController extends BaseController {
  final AppRepository _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;
  /// Full unfiltered set — counters always read from here.
  final RxList<MaintenanceTask> allTasks = <MaintenanceTask>[].obs;
  final loading = false.obs;

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
    loading.value = true;
    final previous = allTasks.toList();
    try {
      final res = await _repository.getTasks();
      if (!res.isSuccess || res.data == null) {
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
      allTasks.assignAll(
        await TaskAssignmentStore.applyAll(items, memory: previous),
      );
    } catch (_) {
      // Keep the current list so a failed refresh does not wipe assignments.
    } finally {
      loading.value = false;
    }
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
    try {
      await _repository.updateTask(task.id, updated.toUpdateRequest());
    } catch (_) {
      // Keep the local status so the Completed tab stays accurate offline.
    }
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
    if (result == true) loadTasks();
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
