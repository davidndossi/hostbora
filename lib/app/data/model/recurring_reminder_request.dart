class RecurringReminderRequest {
  RecurringReminderRequest({
    this.tenantId = '',
    this.tenantName = '',
    this.propertyRef = '',
    this.propertyLabel = '',
    this.recipientPhone = '',
    this.reminderType = 'pay_rent',
    this.customTypeLabel = '',
    this.amountTsh = 0,
    this.messageTemplate = '',
    this.recurrence = 'monthly_first',
    this.timeOfDay = '09:00',
    this.pushEnabled = true,
    this.whatsappEnabled = true,
    this.smsEnabled = false,
    this.active = true,
    this.continueAfterLeaseExpiry,
    this.leaseEndIso = '',
    this.nextRunAtIso = '',
  });

  final String tenantId;
  final String tenantName;
  final String propertyRef;
  final String propertyLabel;
  final String recipientPhone;
  final String reminderType;
  final String customTypeLabel;
  final int amountTsh;
  final String messageTemplate;
  final String recurrence;
  final String timeOfDay;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool smsEnabled;
  final bool active;
  final bool? continueAfterLeaseExpiry;
  final String leaseEndIso;
  final String nextRunAtIso;

  Map<String, dynamic> toJson() => {
        if (tenantId.isNotEmpty) 'tenantId': tenantId,
        if (tenantName.isNotEmpty) 'tenantName': tenantName,
        if (propertyRef.isNotEmpty) 'propertyRef': propertyRef,
        if (propertyLabel.isNotEmpty) 'propertyLabel': propertyLabel,
        if (recipientPhone.isNotEmpty) 'recipientPhone': recipientPhone,
        'reminderType': reminderType,
        if (customTypeLabel.isNotEmpty) 'customTypeLabel': customTypeLabel,
        'amountTsh': amountTsh,
        'messageTemplate': messageTemplate,
        'recurrence': recurrence,
        'timeOfDay': timeOfDay,
        'pushEnabled': pushEnabled,
        'whatsappEnabled': whatsappEnabled,
        'smsEnabled': smsEnabled,
        'active': active,
        if (continueAfterLeaseExpiry != null)
          'continueAfterLeaseExpiry': continueAfterLeaseExpiry,
        if (leaseEndIso.isNotEmpty) 'leaseEndIso': leaseEndIso,
        if (nextRunAtIso.isNotEmpty) 'nextRunAtIso': nextRunAtIso,
      };
}

class BulkRecurringReminderRequest {
  BulkRecurringReminderRequest({
    this.propertyRef = '',
    this.scope = 'property',
    this.reminderType = 'pay_rent',
    this.customTypeLabel = '',
    this.messageTemplate = '',
    this.recurrence = 'monthly_first',
    this.timeOfDay = '09:00',
    this.pushEnabled = true,
    this.whatsappEnabled = true,
    this.smsEnabled = false,
    this.tenants = const [],
  });

  final String propertyRef;
  final String scope;
  final String reminderType;
  final String customTypeLabel;
  final String messageTemplate;
  final String recurrence;
  final String timeOfDay;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool smsEnabled;
  final List<RecurringReminderRequest> tenants;

  Map<String, dynamic> toJson() => {
        if (propertyRef.isNotEmpty) 'propertyRef': propertyRef,
        'scope': scope,
        'reminderType': reminderType,
        if (customTypeLabel.isNotEmpty) 'customTypeLabel': customTypeLabel,
        'messageTemplate': messageTemplate,
        'recurrence': recurrence,
        'timeOfDay': timeOfDay,
        'pushEnabled': pushEnabled,
        'whatsappEnabled': whatsappEnabled,
        'smsEnabled': smsEnabled,
        'tenants': tenants.map((e) => e.toJson()).toList(),
      };
}
