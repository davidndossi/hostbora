import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentScheduledMaintenanceRecord {
  const RentScheduledMaintenanceRecord({
    required this.id,
    required this.propertyLabel,
    required this.category,
    required this.description,
    required this.scheduledDateIso,
    required this.priority,
    required this.notificationId,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final String propertyLabel;
  final String category;
  final String description;
  final String scheduledDateIso;
  final String priority;
  final int notificationId;
  final String syncStatus;
  final int createdAtMs;

  factory RentScheduledMaintenanceRecord.fromMap(Map<String, Object?> m) {
    return RentScheduledMaintenanceRecord(
      id: m['id']! as int,
      propertyLabel: m['property_label'] as String? ?? '',
      category: m['category'] as String? ?? '',
      description: m['description'] as String? ?? '',
      scheduledDateIso: m['scheduled_date_iso'] as String? ?? '',
      priority: m['priority'] as String? ?? 'medium',
      notificationId: m['notification_id'] as int? ?? 0,
      syncStatus: m['sync_status'] as String? ?? 'pending',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentScheduledMaintenanceLocalDataSource {
  static const _table = AppLocalDatabase.rentScheduledMaintenanceTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String propertyLabel,
    required String category,
    required String description,
    required String scheduledDateIso,
    required String priority,
    required int notificationId,
    required String syncStatus,
  }) async {
    final db = await database;
    return db.insert(_table, {
      'property_label': propertyLabel,
      'category': category,
      'description': description,
      'scheduled_date_iso': scheduledDateIso,
      'priority': priority,
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

  Future<List<RentScheduledMaintenanceRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentScheduledMaintenanceRecord.fromMap).toList();
  }
}
