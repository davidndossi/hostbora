/// Request body for POST /api/payment-reminders.
class SchedulePaymentReminderRequest {
  SchedulePaymentReminderRequest({
    required this.reminderAtIso,
    this.tenantName = '',
    this.propertyLabel = '',
    this.balanceTsh = 0,
    this.pushEnabled = true,
    this.whatsappEnabled = false,
    this.emailEnabled = false,
    this.notificationId = 0,
  });

  final String reminderAtIso;
  final String tenantName;
  final String propertyLabel;
  final int balanceTsh;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool emailEnabled;
  final int notificationId;

  Map<String, dynamic> toJson() => {
        'reminderAtIso': reminderAtIso,
        if (tenantName.isNotEmpty) 'tenantName': tenantName,
        if (propertyLabel.isNotEmpty) 'propertyLabel': propertyLabel,
        'balanceTsh': balanceTsh,
        'pushEnabled': pushEnabled,
        'whatsappEnabled': whatsappEnabled,
        'emailEnabled': emailEnabled,
        'notificationId': notificationId,
      };

  factory SchedulePaymentReminderRequest.fromJson(Map<String, dynamic> json) =>
      SchedulePaymentReminderRequest(
        reminderAtIso: json['reminderAtIso'] as String? ?? '',
        tenantName: json['tenantName'] as String? ?? '',
        propertyLabel: json['propertyLabel'] as String? ?? '',
        balanceTsh: (json['balanceTsh'] as num?)?.toInt() ?? 0,
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        whatsappEnabled: json['whatsappEnabled'] as bool? ?? false,
        emailEnabled: json['emailEnabled'] as bool? ?? false,
        notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      );
}
