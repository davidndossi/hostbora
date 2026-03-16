import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
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
      if (res.responseCode != '0' || res.data == null) {
        tasks.clear();
        return;
      }
      final raw = res.data!;
      List<dynamic> list = [];
      if (raw['tasks'] is List) {
        list = raw['tasks'] as List;
      } else if (raw is List) {
        list = raw;
      } else if (raw['content'] is List) {
        list = raw['content'] as List;
      }
      var items = list.map((e) => _taskFromMap(e as Map<String, dynamic>)).where((t) => t.id.isNotEmpty).toList();
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

  static MaintenanceTask _taskFromMap(Map<String, dynamic> m) {
    final completed = m['completed'] as bool? ?? false;
    final statusStr = (m['status'] as String?)?.toUpperCase();
    TaskStatus status = completed ? TaskStatus.completed : TaskStatus.pending;
    if (statusStr == 'IN_PROGRESS') status = TaskStatus.inProgress;
    if (statusStr == 'COMPLETED' || completed) status = TaskStatus.completed;
    if (statusStr == 'PENDING') status = TaskStatus.pending;
    DateTime? due;
    final dueStr = m['dueDate'] as String?;
    if (dueStr != null && dueStr.isNotEmpty) due = DateTime.tryParse(dueStr);
    DateTime? completedAt;
    final atStr = m['completedAt'] as String?;
    if (atStr != null && atStr.isNotEmpty) completedAt = DateTime.tryParse(atStr);
    final priorityStr = (m['priority'] as String?)?.toUpperCase();
    TaskPriority priority = TaskPriority.medium;
    if (priorityStr == 'HIGH') priority = TaskPriority.high;
    if (priorityStr == 'LOW') priority = TaskPriority.low;
    final assignee = m['assignee']?.toString() ?? m['assignedTo']?.toString() ?? 'Unassigned';
    return MaintenanceTask(
      id: m['taskId']?.toString() ?? m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      assignee: assignee,
      priority: priority,
      status: status,
      dueDate: due,
      isCompleted: completed,
      completedAt: completedAt,
    );
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

  void addTask() async {
    final result = await Get.toNamed(Routes.ADD_TASK);
    if (result == true) loadTasks();
  }

  void openTaskDetail(MaintenanceTask task) {
    // Placeholder: navigate to task detail
    Get.snackbar('Task', task.title);
  }
}
