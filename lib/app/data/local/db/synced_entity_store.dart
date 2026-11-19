import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Phone copy of a server row that has no dedicated SQLite table.
class SyncedEntityRow {
  const SyncedEntityRow({
    required this.entityKey,
    required this.payload,
    required this.remoteUpdatedAtMs,
    required this.localUpdatedAtMs,
  });

  final String entityKey;
  final Map<String, dynamic> payload;
  final int remoteUpdatedAtMs;
  final int localUpdatedAtMs;
}

class SyncedEntityStore {
  static const bookingType = 'booking';
  static const taskType = 'task';
  static const calendarType = 'calendar_subscription';

  static const _table = AppLocalDatabase.syncedEntityTable;

  Future<Database> get database => AppLocalDatabase.database;

  Future<List<SyncedEntityRow>> load(String entityType) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'entity_type = ?',
      whereArgs: [entityType],
    );
    return maps.map(_fromMap).where((row) => row.entityKey.isNotEmpty).toList();
  }

  Future<SyncedEntityRow?> find(String entityType, String entityKey) async {
    final key = entityKey.trim();
    if (key.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'entity_type = ? AND entity_key = ?',
      whereArgs: [entityType, key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Writes [payload] unless the phone row is already newer than [remoteUpdatedAtMs].
  Future<void> saveRemoteIfNotOlder({
    required String entityType,
    required String entityKey,
    required Map<String, dynamic> payload,
    required int remoteUpdatedAtMs,
    int? localUpdatedAtMs,
  }) async {
    final key = entityKey.trim();
    if (key.isEmpty) return;
    final existing = await find(entityType, key);
    if (existing != null &&
        existing.localUpdatedAtMs > remoteUpdatedAtMs &&
        existing.localUpdatedAtMs > 0) {
      return;
    }
    final localMs = localUpdatedAtMs ?? remoteUpdatedAtMs;
    await _write(
      entityType: entityType,
      entityKey: key,
      payload: payload,
      remoteUpdatedAtMs: remoteUpdatedAtMs,
      localUpdatedAtMs: localMs,
    );
  }

  Future<void> saveLocal({
    required String entityType,
    required String entityKey,
    required Map<String, dynamic> payload,
    required int localUpdatedAtMs,
    int remoteUpdatedAtMs = 0,
  }) async {
    final key = entityKey.trim();
    if (key.isEmpty) return;
    await _write(
      entityType: entityType,
      entityKey: key,
      payload: payload,
      remoteUpdatedAtMs: remoteUpdatedAtMs,
      localUpdatedAtMs: localUpdatedAtMs,
    );
  }

  Future<void> _write({
    required String entityType,
    required String entityKey,
    required Map<String, dynamic> payload,
    required int remoteUpdatedAtMs,
    required int localUpdatedAtMs,
  }) async {
    final db = await database;
    await db.insert(
      _table,
      {
        'entity_type': entityType,
        'entity_key': entityKey,
        'payload_json': jsonEncode(payload),
        'remote_updated_at_ms': remoteUpdatedAtMs,
        'local_updated_at_ms': localUpdatedAtMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  SyncedEntityRow _fromMap(Map<String, Object?> map) {
    Map<String, dynamic> payload = const {};
    final raw = map['payload_json'] as String? ?? '';
    if (raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return SyncedEntityRow(
      entityKey: map['entity_key'] as String? ?? '',
      payload: payload,
      remoteUpdatedAtMs: (map['remote_updated_at_ms'] as num?)?.toInt() ?? 0,
      localUpdatedAtMs: (map['local_updated_at_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
