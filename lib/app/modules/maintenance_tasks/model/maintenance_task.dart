enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed }

class MaintenanceTask {
  final String id;
  final String title;
  final String assignee;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;

  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.assignee,
    this.description = '',
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
    String? description,
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
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// For [Get.toNamed] / [Get.arguments] (detail → edit prefill).
  Map<String, dynamic> toArguments() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'assignee': assignee,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'isCompleted': isCompleted,
      if (dueDate != null) 'dueDateMs': dueDate!.millisecondsSinceEpoch,
      if (completedAt != null) 'completedAtMs': completedAt!.millisecondsSinceEpoch,
    };
  }

  factory MaintenanceTask.fromArguments(Map<String, dynamic> raw) {
    final id = raw['id']?.toString() ?? '';
    final title = raw['title']?.toString() ?? '';
    final assignee = raw['assignee']?.toString() ?? '';
    final description = raw['description']?.toString() ?? '';

    TaskPriority priority = TaskPriority.medium;
    switch (raw['priority']?.toString()) {
      case 'high':
        priority = TaskPriority.high;
        break;
      case 'low':
        priority = TaskPriority.low;
        break;
      case 'medium':
      default:
        priority = TaskPriority.medium;
    }

    TaskStatus status = TaskStatus.pending;
    switch (raw['status']?.toString()) {
      case 'inProgress':
        status = TaskStatus.inProgress;
        break;
      case 'completed':
        status = TaskStatus.completed;
        break;
      case 'pending':
      default:
        status = TaskStatus.pending;
    }

    DateTime? dueDate;
    final dm = raw['dueDateMs'];
    if (dm is int) {
      dueDate = DateTime.fromMillisecondsSinceEpoch(dm);
    }

    DateTime? completedAt;
    final cm = raw['completedAtMs'];
    if (cm is int) {
      completedAt = DateTime.fromMillisecondsSinceEpoch(cm);
    }

    final isCompleted = raw['isCompleted'] == true;

    return MaintenanceTask(
      id: id,
      title: title,
      assignee: assignee,
      description: description,
      priority: priority,
      status: status,
      dueDate: dueDate,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }

  /// Parses one task object from GET list/detail or nested API payloads.
  factory MaintenanceTask.fromApiMap(Map<String, dynamic> m) {
    final completed = m['completed'] as bool? ?? false;
    final statusStr = (m['status'] as String?)?.toUpperCase();
    TaskStatus status = completed ? TaskStatus.completed : TaskStatus.pending;
    if (statusStr == 'IN_PROGRESS') status = TaskStatus.inProgress;
    if (statusStr == 'COMPLETED' || completed) status = TaskStatus.completed;
    if (statusStr == 'PENDING') status = TaskStatus.pending;

    DateTime? due;
    final dueStr = m['dueDate'] as String?;
    if (dueStr != null && dueStr.isNotEmpty) {
      due = DateTime.tryParse(dueStr);
    }

    DateTime? completedAt;
    final atStr = m['completedAt'] as String?;
    if (atStr != null && atStr.isNotEmpty) {
      completedAt = DateTime.tryParse(atStr);
    }

    final priorityStr = (m['priority'] as String?)?.toUpperCase();
    TaskPriority priority = TaskPriority.medium;
    if (priorityStr == 'HIGH') priority = TaskPriority.high;
    if (priorityStr == 'LOW') priority = TaskPriority.low;

    final assignee =
        m['assignee']?.toString() ?? m['assignedTo']?.toString() ?? 'Unassigned';
    final description = m['description']?.toString() ?? '';

    return MaintenanceTask(
      id: m['taskId']?.toString() ?? m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      assignee: assignee,
      description: description,
      priority: priority,
      status: status,
      dueDate: due,
      isCompleted: completed,
      completedAt: completedAt,
    );
  }
}
