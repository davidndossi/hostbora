/// Request body for POST /api/tasks
class AddTaskRequest {
  AddTaskRequest({
    required this.title,
    this.description,
    this.dueDate,
  });

  final String title;
  final String? description;
  /// ISO date string (yyyy-MM-dd), e.g. "2025-03-15"
  final String? dueDate;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (dueDate != null && dueDate!.isNotEmpty) 'dueDate': dueDate,
    };
  }
}
