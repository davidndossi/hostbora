import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../model/maintenance_task.dart';

enum TaskFilter { all, pending, inProgress, completed }

/// Status sent to API for filter: null = all, PENDING, IN_PROGRESS, COMPLETED.
const List<String?> _taskFilterStatuses = [null, 'PENDING', 'IN_PROGRESS', 'COMPLETED'];

class MaintenanceTasksController extends BaseController {
  final AppRepository _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;
  /// Tasks loaded from service by status (no static list).
  final RxList<MaintenanceTask> tasks = <MaintenanceTask>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  /// Fetches tasks from service by current filter (All / Pending / In Progress / Completed).
  Future<void> loadTasks() async {
    loading.value = true;
    try {
      final status = _taskFilterStatuses[selectedFilter.value.index];
      final res = await _repository.getTasks(status: status);
      if (!res.isSuccess || res.data == null) {
        tasks.clear();
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
      var items = list
          .whereType<Map>()
          .map((e) => MaintenanceTask.fromApiMap(Map<String, dynamic>.from(e)))
          .where((t) => t.id.isNotEmpty)
          .toList();
      if (status != null && status.isNotEmpty) {
        items = items.where((t) => _statusMatchesFilter(t, status)).toList();
      }
      tasks.assignAll(items);
    } catch (_) {
      tasks.clear();
    } finally {
      loading.value = false;
    }
  }

  static bool _statusMatchesFilter(MaintenanceTask t, String status) {
    switch (status) {
      case 'PENDING':
        return t.status == TaskStatus.pending;
      case 'IN_PROGRESS':
        return t.status == TaskStatus.inProgress;
      case 'COMPLETED':
        return t.status == TaskStatus.completed;
      default:
        return true;
    }
  }

  /// Counts from the currently-loaded list so chips are always accurate.
  int get countAll => tasks.length;
  int get countPending =>
      tasks.where((t) => t.status == TaskStatus.pending).length;
  int get countInProgress =>
      tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get countCompleted =>
      tasks.where((t) => t.status == TaskStatus.completed).length;

  void setFilter(TaskFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
    loadTasks();
  }

  void toggleComplete(MaintenanceTask task) {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    final now = DateTime.now();
    tasks[idx] = task.copyWith(
      isCompleted: !task.isCompleted,
      status: task.isCompleted ? TaskStatus.pending : TaskStatus.completed,
      completedAt: task.isCompleted ? null : now,
    );
  }

  void completeTaskFromSwipe(MaintenanceTask task) {
    if (task.isCompleted) return;
    toggleComplete(task);
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
        final idx = tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          tasks[idx] = task.copyWith(dueDate: newDue);
        }
        hapticPrimaryConfirm();
        showSuccessMessage(
          'Due ${DateFormat('MMM d, yyyy').format(newDue)}',
        );
        return;
      }
      showErrorMessage(res.message ?? 'Could not snooze task');
    } catch (e) {
      final idx = tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        tasks[idx] = task.copyWith(dueDate: newDue);
      }
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

  void _mergeTaskIntoList(MaintenanceTask updated) {
    if (updated.id.isEmpty) return;
    final idx = tasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final current = tasks[idx];
    final assignee = _isUnassigned(current.assignee) &&
            !_isUnassigned(updated.assignee)
        ? updated.assignee
        : current.assignee;
    tasks[idx] = current.copyWith(
      assignee: assignee,
      title: updated.title.isNotEmpty ? updated.title : current.title,
      description: updated.description.isNotEmpty
          ? updated.description
          : current.description,
      dueDate: updated.dueDate ?? current.dueDate,
      status: updated.status,
      isCompleted: updated.isCompleted,
      completedAt: updated.completedAt ?? current.completedAt,
    );
  }

  static bool _isUnassigned(String value) {
    final s = value.trim().toLowerCase();
    return s.isEmpty || s == 'unassigned' || s == '—' || s == '-';
  }
}
