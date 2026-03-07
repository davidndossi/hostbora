import 'notification.dart';

class NotificationResponse {
  NotificationResponse({
    this.totalCount,
    this.incompleteResults,
    this.notifications,
  });

  NotificationResponse.fromJson(dynamic json) {
    totalCount = json['total_count'];
    incompleteResults = json['incomplete_results'];
    if (json['history'] != null) {
      notifications = [];
      json['history'].forEach((v) {
        notifications?.add(Notification.fromJson(v));
      });
    }
  }

  int? totalCount;
  bool? incompleteResults;
  List<Notification>? notifications;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_count'] = totalCount;
    map['incomplete_results'] = incompleteResults;
    if (notifications != null) {
      map['notifications'] = notifications?.map((v) => v.toJson()).toList();
    }

    return map;
  }
}
