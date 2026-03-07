import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../model/maintenance_task.dart';

enum TaskFilter { all, pending, inProgress, completed }

class MaintenanceTasksController extends BaseController {
  final Rx<TaskFilter> selectedFilter = TaskFilter.all.obs;
  final RxList<MaintenanceTask> tasks = <MaintenanceTask>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSampleTasks();
  }

  void _loadSampleTasks() {
    final now = DateTime.now();
    tasks.assignAll([
      MaintenanceTask(
        id: '1',
        title: 'Clean Beach House',
        assignee: 'Sarah',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: now.copyWith(hour: 16, minute: 0),
      ),
      MaintenanceTask(
        id: '2',
        title: 'Fix Leaky Faucet - Unit 402',
        assignee: 'Mike',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: now.add(const Duration(days: 1)).copyWith(hour: 10, minute: 0),
      ),
      MaintenanceTask(
        id: '3',
        title: 'Gardening - Mountain Cabin',
        assignee: 'GreenScapes',
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        dueDate: now.add(const Duration(days: 3)).copyWith(hour: 9, minute: 0),
      ),
      MaintenanceTask(
        id: '4',
        title: 'Restock Toiletries - Studio 3',
        assignee: 'Sarah',
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  List<MaintenanceTask> get filteredTasks {
    switch (selectedFilter.value) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.pending:
        return tasks.where((t) => t.status == TaskStatus.pending).toList();
      case TaskFilter.inProgress:
        return tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
    }
  }

  void setFilter(TaskFilter filter) {
    selectedFilter.value = filter;
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

  void addTask() {
    // Placeholder: navigate to add task screen or show dialog
    Get.snackbar('Add Task', 'Add task flow can be implemented here.');
  }

  void openTaskDetail(MaintenanceTask task) {
    // Placeholder: navigate to task detail
    Get.snackbar('Task', task.title);
  }
}
