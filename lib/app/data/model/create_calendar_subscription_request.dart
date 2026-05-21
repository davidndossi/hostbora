/// Body for POST /api/calendar/subscriptions.
class CreateCalendarSubscriptionRequest {
  CreateCalendarSubscriptionRequest({
    required this.listingId,
    required this.direction,
    this.unitId,
    this.sourceUrl,
    this.label,
    this.enabled = true,
  });

  final String listingId;
  final String direction;
  final String? unitId;
  final String? sourceUrl;
  final String? label;
  final bool enabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'listingId': listingId,
        'direction': direction,
        if (unitId != null && unitId!.isNotEmpty) 'unitId': unitId,
        if (sourceUrl != null && sourceUrl!.isNotEmpty) 'sourceUrl': sourceUrl,
        if (label != null && label!.isNotEmpty) 'label': label,
        'enabled': enabled,
      };
}
