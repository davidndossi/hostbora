/// Body for POST /api/calendar/import/sync.
class CalendarSyncRequest {
  CalendarSyncRequest({this.listingId, this.subscriptionId});

  final String? listingId;
  final String? subscriptionId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (listingId != null && listingId!.isNotEmpty) {
      map['listingId'] = listingId;
    }
    if (subscriptionId != null && subscriptionId!.isNotEmpty) {
      map['subscriptionId'] = subscriptionId;
    }
    return map;
  }
}
