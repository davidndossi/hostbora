import '../../../core/utils/sync_freshness.dart';
import '../../../data/model/add_task_request.dart';

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

  /// Server edit time. `0` when the payload did not include one.
  final int remoteUpdatedAtMs;

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
    this.remoteUpdatedAtMs = 0,
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
    int? remoteUpdatedAtMs,
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
      remoteUpdatedAtMs: remoteUpdatedAtMs ?? this.remoteUpdatedAtMs,
    );
  }

  /// Builds a PUT body that preserves current task fields (avoids clearing assignee/due date).
  AddTaskRequest toUpdateRequest({
    String? assigneeOverride,
    String? dueDateOverride,
    String? assigneePhone,
    String? staffId,
  }) {
    String? dueIso = dueDateOverride;
    if (dueIso == null && dueDate != null) {
      final d = dueDate!;
      dueIso =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    final rawAssignee = assigneeOverride ?? assignee;
    final trimmed = rawAssignee.trim();
    final assigneeValue = trimmed.isEmpty || trimmed.toLowerCase() == 'unassigned'
        ? null
        : trimmed;
    return AddTaskRequest(
      title: title,
      description: description.trim().isEmpty ? null : description.trim(),
      dueDate: dueIso,
      assignee: assigneeValue,
      assigneePhone: assigneePhone,
      staffId: staffId,
      completed: isCompleted,
      status: apiStatus,
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

    final isCompleted =
        raw['isCompleted'] == true || status == TaskStatus.completed;
    if (status == TaskStatus.pending &&
        !isCompleted &&
        _hasAssignee(assignee)) {
      status = TaskStatus.inProgress;
    }

    return MaintenanceTask(
      id: id,
      title: title,
      assignee: assignee,
      description: description,
      priority: priority,
      status: isCompleted ? TaskStatus.completed : status,
      dueDate: dueDate,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }

  /// Parses one task object from GET list/detail or nested API payloads.
  factory MaintenanceTask.fromApiMap(Map<String, dynamic> m) {
    final completedFlag = _readBool(m['completed']) ||
        _readBool(m['isCompleted']) ||
        _readBool(m['done']);
    final statusStr = (m['status'] ?? '')
        .toString()
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    TaskStatus status;
    if (completedFlag ||
        statusStr == 'COMPLETED' ||
        statusStr == 'DONE' ||
        statusStr == 'COMPLETE') {
      status = TaskStatus.completed;
    } else if (statusStr == 'IN_PROGRESS' ||
        statusStr == 'INPROGRESS' ||
        statusStr == 'STARTED' ||
        statusStr == 'PROGRESS') {
      status = TaskStatus.inProgress;
    } else {
      status = TaskStatus.pending;
    }

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

    final rawAssignee = _readAssignee(
      m['assignee'] ?? m['assignedTo'] ?? m['assigneeName'] ?? m['staffName'],
    );
    final assignee = rawAssignee.isEmpty || rawAssignee.toLowerCase() == 'null'
        ? 'Unassigned'
        : rawAssignee;
    final description = m['description']?.toString() ?? '';
    if (status == TaskStatus.pending && _hasAssignee(assignee)) {
      status = TaskStatus.inProgress;
    }

    final isCompleted = completedFlag || status == TaskStatus.completed;

    return MaintenanceTask(
      id: m['taskId']?.toString() ?? m['id']?.toString() ?? '',
      title: (m['title'] ?? m['name'] ?? m['taskName'] ?? m['task_name'] ?? '')
          .toString(),
      assignee: assignee,
      description: description,
      priority: priority,
      status: status,
      dueDate: due,
      isCompleted: isCompleted,
      completedAt: completedAt,
      remoteUpdatedAtMs: SyncFreshness.fromMap(m),
    );
  }

  static String _readAssignee(dynamic raw) {
    if (raw is Map) {
      return (raw['name'] ??
              raw['fullName'] ??
              raw['assignee'] ??
              raw['phone'] ??
              '')
          .toString()
          .trim();
    }
    return raw?.toString().trim() ?? '';
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static bool _hasAssignee(String value) {
    final s = value.trim().toLowerCase();
    return s.isNotEmpty && s != 'unassigned' && s != '—' && s != '-';
  }

  String get apiStatus {
    switch (status) {
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.pending:
        return 'PENDING';
    }
  }
}
