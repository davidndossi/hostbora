import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentPaymentReminderRecord {
  const RentPaymentReminderRecord({
    required this.id,
    required this.tenantName,
    required this.propertyLabel,
    required this.balanceTsh,
    required this.reminderAtIso,
    required this.pushEnabled,
    required this.whatsappEnabled,
    required this.emailEnabled,
    required this.notificationId,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final String tenantName;
  final String propertyLabel;
  final int balanceTsh;
  final String reminderAtIso;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool emailEnabled;
  final int notificationId;
  final String syncStatus;
  final int createdAtMs;

  factory RentPaymentReminderRecord.fromMap(Map<String, Object?> m) {
    return RentPaymentReminderRecord(
      id: m['id']! as int,
      tenantName: m['tenant_name'] as String? ?? '',
      propertyLabel: m['property_label'] as String? ?? '',
      balanceTsh: m['balance_tsh'] as int? ?? 0,
      reminderAtIso: m['reminder_at_iso'] as String? ?? '',
      pushEnabled: (m['push_enabled'] as int? ?? 0) == 1,
      whatsappEnabled: (m['whatsapp_enabled'] as int? ?? 0) == 1,
      emailEnabled: (m['email_enabled'] as int? ?? 0) == 1,
      notificationId: m['notification_id'] as int? ?? 0,
      syncStatus: m['sync_status'] as String? ?? 'pending',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentPaymentReminderLocalDataSource {
  static const _table = AppLocalDatabase.rentPaymentReminderTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String tenantName,
    required String propertyLabel,
    required int balanceTsh,
    required String reminderAtIso,
    required bool pushEnabled,
    required bool whatsappEnabled,
    required bool emailEnabled,
    required int notificationId,
    required String syncStatus,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'tenant_name': tenantName,
      'property_label': propertyLabel,
      'balance_tsh': balanceTsh,
      'reminder_at_iso': reminderAtIso,
      'push_enabled': pushEnabled ? 1 : 0,
      'whatsapp_enabled': whatsappEnabled ? 1 : 0,
      'email_enabled': emailEnabled ? 1 : 0,
      'notification_id': notificationId,
      'sync_status': syncStatus,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
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

  Future<List<RentPaymentReminderRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentPaymentReminderRecord.fromMap).toList();
  }
}
