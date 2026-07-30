import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RecurringReminderRecord {
  const RecurringReminderRecord({
    required this.id,
    required this.backendId,
    required this.tenantId,
    required this.tenantName,
    required this.propertyRef,
    required this.propertyLabel,
    required this.recipientPhone,
    required this.reminderType,
    required this.customTypeLabel,
    required this.amountTsh,
    required this.messageTemplate,
    required this.recurrence,
    required this.timeOfDay,
    required this.pushEnabled,
    required this.whatsappEnabled,
    required this.smsEnabled,
    required this.active,
    required this.continueAfterLeaseExpiry,
    required this.leaseEndIso,
    required this.nextRunAtIso,
    required this.lastSentAtIso,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final String backendId;
  final int tenantId;
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
  final int? continueAfterLeaseExpiry;
  final String leaseEndIso;
  final String nextRunAtIso;
  final String lastSentAtIso;
  final String syncStatus;
  final int createdAtMs;

  factory RecurringReminderRecord.fromMap(Map<String, Object?> m) {
    int? leaseDecision;
    final raw = m['continue_after_lease_expiry'];
    if (raw is int) leaseDecision = raw;

    return RecurringReminderRecord(
      id: m['id']! as int,
      backendId: m['backend_id'] as String? ?? '',
      tenantId: m['tenant_id'] as int? ?? 0,
      tenantName: m['tenant_name'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      propertyLabel: m['property_label'] as String? ?? '',
      recipientPhone: m['recipient_phone'] as String? ?? '',
      reminderType: m['reminder_type'] as String? ?? 'pay_rent',
      customTypeLabel: m['custom_type_label'] as String? ?? '',
      amountTsh: m['amount_tsh'] as int? ?? 0,
      messageTemplate: m['message_template'] as String? ?? '',
      recurrence: m['recurrence'] as String? ?? 'monthly_first',
      timeOfDay: m['time_of_day'] as String? ?? '09:00',
      pushEnabled: (m['push_enabled'] as int? ?? 1) == 1,
      whatsappEnabled: (m['whatsapp_enabled'] as int? ?? 1) == 1,
      smsEnabled: (m['sms_enabled'] as int? ?? 0) == 1,
      active: (m['active'] as int? ?? 1) == 1,
      continueAfterLeaseExpiry: leaseDecision,
      leaseEndIso: m['lease_end_iso'] as String? ?? '',
      nextRunAtIso: m['next_run_at_iso'] as String? ?? '',
      lastSentAtIso: m['last_sent_at_iso'] as String? ?? '',
      syncStatus: m['sync_status'] as String? ?? 'pending',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toApiJson() => {
        if (backendId.isNotEmpty) 'id': backendId,
        if (tenantId > 0) 'tenantId': '$tenantId',
        'tenantName': tenantName,
        'propertyRef': propertyRef,
        'propertyLabel': propertyLabel,
        'recipientPhone': recipientPhone,
        'reminderType': reminderType,
        'customTypeLabel': customTypeLabel,
        'amountTsh': amountTsh,
        'messageTemplate': messageTemplate,
        'recurrence': recurrence,
        'timeOfDay': timeOfDay,
        'pushEnabled': pushEnabled,
        'whatsappEnabled': whatsappEnabled,
        'smsEnabled': smsEnabled,
        'active': active,
        if (continueAfterLeaseExpiry != null)
          'continueAfterLeaseExpiry': continueAfterLeaseExpiry == 1,
        'leaseEndIso': leaseEndIso,
        'nextRunAtIso': nextRunAtIso,
      };
}

class RecurringReminderLocalDataSource {
  static const _table = AppLocalDatabase.recurringReminderTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required int tenantId,
    required String tenantName,
    required String propertyRef,
    required String propertyLabel,
    required String recipientPhone,
    required String reminderType,
    required String customTypeLabel,
    required int amountTsh,
    required String messageTemplate,
    required String recurrence,
    required String timeOfDay,
    required bool pushEnabled,
    required bool whatsappEnabled,
    required bool smsEnabled,
    required bool active,
    int? continueAfterLeaseExpiry,
    required String leaseEndIso,
    required String nextRunAtIso,
    String backendId = '',
    String syncStatus = 'pending',
  }) async {
    final db = await database;
    return db.insert(_table, {
      'backend_id': backendId,
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'property_ref': propertyRef,
      'property_label': propertyLabel,
      'recipient_phone': recipientPhone,
      'reminder_type': reminderType,
      'custom_type_label': customTypeLabel,
      'amount_tsh': amountTsh,
      'message_template': messageTemplate,
      'recurrence': recurrence,
      'time_of_day': timeOfDay,
      'push_enabled': pushEnabled ? 1 : 0,
      'whatsapp_enabled': whatsappEnabled ? 1 : 0,
      'sms_enabled': smsEnabled ? 1 : 0,
      'active': active ? 1 : 0,
      'continue_after_lease_expiry': continueAfterLeaseExpiry,
      'lease_end_iso': leaseEndIso,
      'next_run_at_iso': nextRunAtIso,
      'last_sent_at_iso': '',
      'sync_status': syncStatus,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateBackendId(int id, String backendId) async {
    final db = await database;
    await db.update(
      _table,
      {'backend_id': backendId, 'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatus(int id, String syncStatus) async {
    final db = await database;
    await db.update(
      _table,
      {'sync_status': syncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateNextRun({
    required int id,
    required String nextRunAtIso,
    String lastSentAtIso = '',
    bool? active,
  }) async {
    final db = await database;
    final values = <String, Object?>{
      'next_run_at_iso': nextRunAtIso,
      if (lastSentAtIso.isNotEmpty) 'last_sent_at_iso': lastSentAtIso,
      if (active != null) 'active': active ? 1 : 0,
    };
    await db.update(_table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateLeaseDecision({
    required int id,
    required int continueAfterLeaseExpiry,
    required bool active,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'continue_after_lease_expiry': continueAfterLeaseExpiry,
        'active': active ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RecurringReminderRecord>> getDueActive({DateTime? before}) async {
    final db = await database;
    final cutoff = (before ?? DateTime.now()).toIso8601String();
    final maps = await db.query(
      _table,
      where: 'active = 1 AND next_run_at_iso <= ? AND recurrence != ?',
      whereArgs: [cutoff, 'once'],
      orderBy: 'next_run_at_iso ASC',
    );
    return maps.map(RecurringReminderRecord.fromMap).toList();
  }

  Future<List<RecurringReminderRecord>> getPendingLeaseDecisions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query(
      _table,
      where:
          'active = 1 AND continue_after_lease_expiry IS NULL AND lease_end_iso != ? AND lease_end_iso < ?',
      whereArgs: ['', now],
      orderBy: 'lease_end_iso ASC',
    );
    return maps.map(RecurringReminderRecord.fromMap).toList();
  }

  Future<List<RecurringReminderRecord>> getAllActive() async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'active = 1',
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(RecurringReminderRecord.fromMap).toList();
  }

  Future<List<RecurringReminderRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RecurringReminderRecord.fromMap).toList();
  }

  Future<void> deactivate(int id) async {
    final db = await database;
    await db.update(_table, {'active': 0}, where: 'id = ?', whereArgs: [id]);
  }
}
