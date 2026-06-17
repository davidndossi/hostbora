import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class InventoryMovementRecord {
  const InventoryMovementRecord({
    required this.id,
    required this.itemLocalId,
    required this.clientMovementId,
    required this.backendMovementId,
    required this.movementType,
    required this.quantityDelta,
    required this.notes,
    required this.syncStatus,
    required this.createdAtMs,
  });

  final int id;
  final int itemLocalId;
  final String clientMovementId;
  final String backendMovementId;
  final String movementType;
  final int quantityDelta;
  final String notes;
  final String syncStatus;
  final int createdAtMs;

  factory InventoryMovementRecord.fromMap(Map<String, Object?> m) {
    return InventoryMovementRecord(
      id: m['id']! as int,
      itemLocalId: m['item_local_id'] as int? ?? 0,
      clientMovementId: m['client_movement_id'] as String? ?? '',
      backendMovementId: m['backend_movement_id'] as String? ?? '',
      movementType: m['movement_type'] as String? ?? 'adjust',
      quantityDelta: (m['quantity_delta'] as num?)?.toInt() ?? 0,
      notes: m['notes'] as String? ?? '',
      syncStatus: m['sync_status'] as String? ?? 'pending',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class InventoryMovementLocalDataSource {
  static const _table = AppLocalDatabase.inventoryMovementTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required int itemLocalId,
    required String clientMovementId,
    required String movementType,
    required int quantityDelta,
    String notes = '',
    String syncStatus = 'pending',
  }) async {
    final db = await database;
    return db.insert(_table, {
      'item_local_id': itemLocalId,
      'client_movement_id': clientMovementId.trim(),
      'backend_movement_id': '',
      'movement_type': movementType.trim(),
      'quantity_delta': quantityDelta,
      'notes': notes.trim(),
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

  Future<void> saveBackendMovementId({
    required int localId,
    required String backendId,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'backend_movement_id': backendId.trim(),
        'sync_status': 'synced',
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<InventoryMovementRecord>> listForItem(int itemLocalId) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'item_local_id = ?',
      whereArgs: [itemLocalId],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(InventoryMovementRecord.fromMap).toList();
  }

  Future<int> countRecentForProperty({
    required List<int> itemLocalIds,
    required int sinceMs,
  }) async {
    if (itemLocalIds.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(itemLocalIds.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM $_table WHERE item_local_id IN ($placeholders) AND created_at_ms >= ?',
      [...itemLocalIds, sinceMs],
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteForItem(int itemLocalId) async {
    final db = await database;
    await db.delete(
      _table,
      where: 'item_local_id = ?',
      whereArgs: [itemLocalId],
    );
  }
}
