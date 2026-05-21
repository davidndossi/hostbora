/// Body for PUT /api/calendar/subscriptions/{id}.
class UpdateCalendarSubscriptionRequest {
  UpdateCalendarSubscriptionRequest({
    this.sourceUrl,
    this.label,
    this.enabled,
  });

  final String? sourceUrl;
  final String? label;
  final bool? enabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (sourceUrl != null) map['sourceUrl'] = sourceUrl;
    if (label != null) map['label'] = label;
    if (enabled != null) map['enabled'] = enabled;
    return map;
  }
}
