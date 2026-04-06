import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentNotificationLogRecord {
  const RentNotificationLogRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.payload,
    required this.isRead,
    required this.createdAtMs,
  });

  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String payload;
  final bool isRead;
  final int createdAtMs;

  factory RentNotificationLogRecord.fromMap(Map<String, Object?> m) {
    return RentNotificationLogRecord(
      id: m['id'] as int? ?? 0,
      type: m['type'] as String? ?? '',
      title: m['title'] as String? ?? '',
      subtitle: m['subtitle'] as String? ?? '',
      actionLabel: m['action_label'] as String? ?? '',
      payload: m['payload'] as String? ?? '',
      isRead: (m['is_read'] as int? ?? 0) == 1,
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentNotificationLogLocalDataSource {
  static const _table = AppLocalDatabase.rentNotificationLogTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String type,
    required String title,
    required String subtitle,
    required String actionLabel,
    required String payload,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'action_label': actionLabel,
      'payload': payload,
      'is_read': 0,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RentNotificationLogRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentNotificationLogRecord.fromMap).toList();
  }

  Future<void> markAllAsRead() async {
    final db = await database;
    await db.update(_table, {'is_read': 1});
  }
}
