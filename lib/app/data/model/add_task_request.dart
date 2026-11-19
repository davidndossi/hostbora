/// Request body for POST /api/tasks and PUT /api/tasks/:id
class AddTaskRequest {
  AddTaskRequest({
    required this.title,
    this.description,
    this.dueDate,
    this.propertyLabel,
    this.propertyRef,
    this.workspaceType,
    this.assignee,
    this.assigneePhone,
    this.staffId,
    this.completed,
    this.status,
  });

  final String title;
  final String? description;

  /// ISO date string (yyyy-MM-dd), e.g. "2025-03-15"
  final String? dueDate;
  final String? propertyLabel;
  final String? propertyRef;
  final String? workspaceType;

  /// Name of the staff member to assign the task to.
  final String? assignee;

  /// Login phone for that staff member, so their account can see the task.
  final String? assigneePhone;

  /// Backend staff id, when the roster row has already synced.
  final String? staffId;
  final bool? completed;
  final String? status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (dueDate != null && dueDate!.isNotEmpty) 'dueDate': dueDate,
      if (propertyLabel != null && propertyLabel!.isNotEmpty)
        'propertyLabel': propertyLabel,
      if (propertyRef != null && propertyRef!.isNotEmpty)
        'propertyRef': propertyRef,
      if (workspaceType != null && workspaceType!.isNotEmpty)
        'workspaceType': workspaceType,
      if (assignee != null && assignee!.isNotEmpty) ...{
        'assignee': assignee,
        'assignedTo': assignee,
      },
      if (assigneePhone != null && assigneePhone!.trim().isNotEmpty)
        'assigneePhone': assigneePhone!.trim(),
      if (staffId != null && staffId!.trim().isNotEmpty) ...{
        'staffId': staffId!.trim(),
        'assigneeStaffId': staffId!.trim(),
      },
      if (completed != null) 'completed': completed,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}
