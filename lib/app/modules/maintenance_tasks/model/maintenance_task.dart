enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed }

class MaintenanceTask {
  final String id;
  final String title;
  final String assignee;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;

  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.assignee,
    required this.priority,
    required this.status,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
  });

  MaintenanceTask copyWith({
    String? id,
    String? title,
    String? assignee,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
