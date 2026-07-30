import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class ScheduledSmsRecord {
  const ScheduledSmsRecord({
    required this.id,
    required this.recipientPhone,
    required this.recipientLabel,
    required this.messageBody,
    required this.scheduledAtIso,
    required this.notificationId,
    required this.sent,
    required this.createdAtMs,
  });

  final int id;
  final String recipientPhone;
  final String recipientLabel;
  final String messageBody;
  final String scheduledAtIso;
  final int notificationId;
  final bool sent;
  final int createdAtMs;

  factory ScheduledSmsRecord.fromMap(Map<String, Object?> m) {
    return ScheduledSmsRecord(
      id: m['id']! as int,
      recipientPhone: m['recipient_phone'] as String? ?? '',
      recipientLabel: m['recipient_label'] as String? ?? '',
      messageBody: m['message_body'] as String? ?? '',
      scheduledAtIso: m['scheduled_at_iso'] as String? ?? '',
      notificationId: m['notification_id'] as int? ?? 0,
      sent: (m['sent'] as int? ?? 0) == 1,
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class ScheduledSmsLocalDataSource {
  static const _table = AppLocalDatabase.scheduledSmsTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String recipientPhone,
    required String recipientLabel,
    required String messageBody,
    required String scheduledAtIso,
    required int notificationId,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'recipient_phone': recipientPhone.trim(),
      'recipient_label': recipientLabel.trim(),
      'message_body': messageBody,
      'scheduled_at_iso': scheduledAtIso,
      'notification_id': notificationId,
      'sent': 0,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ScheduledSmsRecord>> getDueUnsent({DateTime? before}) async {
    final db = await database;
    final cutoff = (before ?? DateTime.now()).toIso8601String();
    final maps = await db.query(
      _table,
      where: 'sent = 0 AND scheduled_at_iso <= ?',
      whereArgs: [cutoff],
      orderBy: 'scheduled_at_iso ASC',
    );
    return maps.map(ScheduledSmsRecord.fromMap).toList();
  }

  Future<void> markSent(int id) async {
    final db = await database;
    await db.update(_table, {'sent': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
