import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Queue row for deferred sync operations when device is offline.
class OfflineSyncQueueItem {
  const OfflineSyncQueueItem({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payloadJson,
    required this.dedupeKey,
    required this.status,
    required this.attemptCount,
    required this.lastError,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final int id;
  final String entityType;
  final String operation;
  final String payloadJson;
  final String dedupeKey;
  final String status;
  final int attemptCount;
  final String lastError;
  final int createdAtMs;
  final int updatedAtMs;

  factory OfflineSyncQueueItem.fromMap(Map<String, Object?> m) {
    return OfflineSyncQueueItem(
      id: m['id']! as int,
      entityType: m['entity_type'] as String? ?? '',
      operation: m['operation'] as String? ?? '',
      payloadJson: m['payload_json'] as String? ?? '',
      dedupeKey: m['dedupe_key'] as String? ?? '',
      status: m['status'] as String? ?? 'pending',
      attemptCount: m['attempt_count'] as int? ?? 0,
      lastError: m['last_error'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      updatedAtMs: m['updated_at_ms'] as int? ?? 0,
    );
  }
}

/// Generic queue data source for offline-first sync workers.
class OfflineSyncQueueLocalDataSource {
  static const _table = AppLocalDatabase.offlineSyncQueueTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  /// Adds a new pending operation.
  ///
  /// If [dedupeKey] is provided and exists, this upserts payload/timestamps
  /// and resets the row to pending.
  Future<int> enqueue({
    required String entityType,
    required String operation,
    required String payloadJson,
    String dedupeKey = '',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = <String, Object?>{
      'entity_type': entityType,
      'operation': operation,
      'payload_json': payloadJson,
      'dedupe_key': dedupeKey,
      'status': 'pending',
      'attempt_count': 0,
      'last_error': '',
      'created_at_ms': now,
      'updated_at_ms': now,
    };

    return db.insert(
      _table,
      data,
      conflictAlgorithm: dedupeKey.isEmpty ? ConflictAlgorithm.abort : ConflictAlgorithm.replace,
    );
  }

  /// Returns the next oldest pending operation.
  Future<OfflineSyncQueueItem?> nextPending() async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at_ms ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineSyncQueueItem.fromMap(rows.first);
  }

  Future<void> markInProgress(int id) async {
    final db = await database;
    await db.update(
      _table,
      {
        'status': 'in_progress',
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markDone(int id) async {
    final db = await database;
    await db.update(
      _table,
      {
        'status': 'done',
        'last_error': '',
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(int id, {required String errorMessage}) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE $_table
      SET
        status = 'failed',
        attempt_count = attempt_count + 1,
        last_error = ?,
        updated_at_ms = ?
      WHERE id = ?
      ''',
      [errorMessage, DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<void> requeueFailed({int maxAttempts = 3}) async {
    final db = await database;
    await db.update(
      _table,
      {
        'status': 'pending',
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'status = ? AND attempt_count < ?',
      whereArgs: ['failed', maxAttempts],
    );
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE status IN (?, ?, ?)',
      ['pending', 'in_progress', 'failed'],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Pending / in-progress / failed `booking:create` rows (not yet removed after sync).
  Future<List<OfflineSyncQueueItem>> listUnsyncedBookingCreates() async {
    return listUnsynced(
      entityType: 'booking',
      operation: 'create',
    );
  }

  Future<List<OfflineSyncQueueItem>> listUnsynced({
    required String entityType,
    String? operation,
  }) async {
    final db = await database;
    final entity = entityType.trim();
    if (entity.isEmpty) return const [];

    final where = StringBuffer('status IN (?, ?, ?) AND entity_type = ?');
    final args = <Object>['pending', 'in_progress', 'failed', entity];
    if (operation != null && operation.trim().isNotEmpty) {
      where.write(' AND operation = ?');
      args.add(operation.trim());
    }
    final rows = await db.query(
      _table,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at_ms ASC',
    );
    return rows.map(OfflineSyncQueueItem.fromMap).toList();
  }

  Future<void> retryItem(int id) async {
    final db = await database;
    await db.update(
      _table,
      {
        'status': 'pending',
        'last_error': '',
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> pendingCountByEntity({
    required String entityType,
    String? operation,
  }) async {
    final db = await database;
    final entity = entityType.trim();
    if (entity.isEmpty) return 0;
    if (operation != null && operation.trim().isNotEmpty) {
      final rows = await db.rawQuery(
        '''
        SELECT COUNT(*) AS c
        FROM $_table
        WHERE status IN (?, ?, ?)
          AND entity_type = ?
          AND operation = ?
        ''',
        ['pending', 'in_progress', 'failed', entity, operation.trim()],
      );
      final v = rows.first['c'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM $_table
      WHERE status IN (?, ?, ?)
        AND entity_type = ?
      ''',
      ['pending', 'in_progress', 'failed', entity],
    );
    final v = rows.first['c'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<void> deleteDone() async {
    final db = await database;
    await db.delete(_table, where: 'status = ?', whereArgs: ['done']);
  }
}
