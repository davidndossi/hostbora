/// Request body for POST /api/scheduled-maintenance
class ScheduledMaintenanceRequest {
  const ScheduledMaintenanceRequest({
    this.propertyLabel,
    this.propertyRef,
    this.apartmentUnitId,
    required this.category,
    this.description,
    this.scheduledDateIso,
    required this.priority,
    this.workspaceType,
  });

  final String? propertyLabel;
  final String? propertyRef;
  final String? apartmentUnitId;
  final String category;
  final String? description;

  /// ISO-8601 datetime string, e.g. "2025-06-15T09:00:00.000"
  final String? scheduledDateIso;
  final String priority;
  final String? workspaceType;

  Map<String, dynamic> toJson() => {
        'category': category,
        'priority': priority,
        if (propertyLabel != null && propertyLabel!.isNotEmpty)
          'propertyLabel': propertyLabel,
        if (propertyRef != null && propertyRef!.isNotEmpty)
          'propertyRef': propertyRef,
        if (apartmentUnitId != null && apartmentUnitId!.isNotEmpty)
          'apartmentUnitId': apartmentUnitId,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (scheduledDateIso != null && scheduledDateIso!.isNotEmpty)
          'scheduledDateIso': scheduledDateIso,
        if (workspaceType != null && workspaceType!.isNotEmpty)
          'workspaceType': workspaceType,
      };
}
