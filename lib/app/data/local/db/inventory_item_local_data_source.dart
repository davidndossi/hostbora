import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class InventoryItemRecord {
  const InventoryItemRecord({
    required this.id,
    required this.clientItemId,
    required this.backendItemId,
    required this.propertyRef,
    required this.propertyLabel,
    required this.apartmentUnitId,
    required this.apartmentUnitName,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.condition,
    required this.locationNote,
    required this.purchaseValue,
    required this.currency,
    required this.syncStatus,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final int id;
  final String clientItemId;
  final String backendItemId;
  final String propertyRef;
  final String propertyLabel;
  final String apartmentUnitId;
  final String apartmentUnitName;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;
  final String condition;
  final String locationNote;
  final double purchaseValue;
  final String currency;
  final String syncStatus;
  final int createdAtMs;
  final int updatedAtMs;

  bool get isLowStock => reorderLevel > 0 && quantity <= reorderLevel;

  factory InventoryItemRecord.fromMap(Map<String, Object?> m) {
    return InventoryItemRecord(
      id: m['id']! as int,
      clientItemId: m['client_item_id'] as String? ?? '',
      backendItemId: m['backend_item_id'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      propertyLabel: m['property_label'] as String? ?? '',
      apartmentUnitId: m['apartment_unit_id'] as String? ?? '',
      apartmentUnitName: m['apartment_unit_name'] as String? ?? '',
      name: m['name'] as String? ?? '',
      category: m['category'] as String? ?? 'Other',
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      reorderLevel: (m['reorder_level'] as num?)?.toInt() ?? 0,
      condition: m['condition'] as String? ?? 'Good',
      locationNote: m['location_note'] as String? ?? '',
      purchaseValue: (m['purchase_value'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? 'TZS',
      syncStatus: m['sync_status'] as String? ?? 'pending',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      updatedAtMs: m['updated_at_ms'] as int? ?? 0,
    );
  }
}

class InventoryItemLocalDataSource {
  static const _table = AppLocalDatabase.inventoryItemTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String clientItemId,
    required String propertyRef,
    required String propertyLabel,
    String apartmentUnitId = '',
    String apartmentUnitName = '',
    required String name,
    required String category,
    required int quantity,
    int reorderLevel = 0,
    String condition = 'Good',
    String locationNote = '',
    double purchaseValue = 0,
    String currency = 'TZS',
    String syncStatus = 'pending',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert(_table, {
      'client_item_id': clientItemId.trim(),
      'backend_item_id': '',
      'property_ref': propertyRef.trim(),
      'property_label': propertyLabel.trim(),
      'apartment_unit_id': apartmentUnitId.trim(),
      'apartment_unit_name': apartmentUnitName.trim(),
      'name': name.trim(),
      'category': category.trim(),
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'condition': condition.trim(),
      'location_note': locationNote.trim(),
      'purchase_value': purchaseValue,
      'currency': currency.trim().isEmpty ? 'TZS' : currency.trim().toUpperCase(),
      'sync_status': syncStatus,
      'created_at_ms': now,
      'updated_at_ms': now,
    });
  }

  Future<void> update({
    required int id,
    required String name,
    required String category,
    required int quantity,
    int reorderLevel = 0,
    String condition = 'Good',
    String locationNote = '',
    double purchaseValue = 0,
    String currency = 'TZS',
    String apartmentUnitId = '',
    String apartmentUnitName = '',
    String? propertyRef,
    String? propertyLabel,
    String syncStatus = 'pending',
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'name': name.trim(),
        'category': category.trim(),
        'quantity': quantity,
        'reorder_level': reorderLevel,
        'condition': condition.trim(),
        'location_note': locationNote.trim(),
        'purchase_value': purchaseValue,
        'currency': currency.trim().isEmpty ? 'TZS' : currency.trim().toUpperCase(),
        'apartment_unit_id': apartmentUnitId.trim(),
        'apartment_unit_name': apartmentUnitName.trim(),
        if (propertyRef != null) 'property_ref': propertyRef.trim(),
        if (propertyLabel != null) 'property_label': propertyLabel.trim(),
        'sync_status': syncStatus,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateQuantity(int id, int quantity) async {
    final db = await database;
    await db.update(
      _table,
      {
        'quantity': quantity,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 'pending',
      },
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

  Future<void> saveBackendItemId({
    required int localId,
    required String backendId,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'backend_item_id': backendId.trim(),
        'sync_status': 'synced',
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<InventoryItemRecord?> getById(int id) async {
    final db = await database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return InventoryItemRecord.fromMap(rows.first);
  }

  Future<List<InventoryItemRecord>> listForProperty({
    required String propertyRef,
    String apartmentUnitId = '',
  }) async {
    final db = await database;
    final ref = propertyRef.trim();
    if (ref.isEmpty) return [];
    final unit = apartmentUnitId.trim();
    final where = unit.isEmpty
        ? 'property_ref = ?'
        : 'property_ref = ? AND apartment_unit_id = ?';
    final args = unit.isEmpty ? [ref] : [ref, unit];
    final maps = await db.query(
      _table,
      where: where,
      whereArgs: args,
      orderBy: 'updated_at_ms DESC',
    );
    return maps.map(InventoryItemRecord.fromMap).toList();
  }

  Future<List<InventoryItemRecord>> listAllForProperty(String propertyRef) async {
    final db = await database;
    final ref = propertyRef.trim();
    if (ref.isEmpty) return [];
    final maps = await db.query(
      _table,
      where: 'property_ref = ?',
      whereArgs: [ref],
      orderBy: 'updated_at_ms DESC',
    );
    return maps.map(InventoryItemRecord.fromMap).toList();
  }

  /// Returns every inventory item across all properties, newest first.
  Future<List<InventoryItemRecord>> listAll() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'updated_at_ms DESC');
    return maps.map(InventoryItemRecord.fromMap).toList();
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertFromRemote(Map<String, dynamic> m) async {
    final backendId = (m['id'] ?? m['itemId'] ?? '').toString().trim();
    if (backendId.isEmpty) return;
    final db = await database;
    final existing = await db.query(
      _table,
      where: 'backend_item_id = ?',
      whereArgs: [backendId],
      limit: 1,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'backend_item_id': backendId,
      'client_item_id': (m['clientItemId'] ?? m['client_item_id'] ?? backendId)
          .toString(),
      'property_ref': (m['propertyRef'] ?? m['property_ref'] ?? '').toString(),
      'property_label':
          (m['propertyLabel'] ?? m['property_label'] ?? '').toString(),
      'apartment_unit_id':
          (m['apartmentUnitId'] ?? m['apartment_unit_id'] ?? '').toString(),
      'apartment_unit_name': (m['apartmentUnitName'] ??
              m['apartment_unit_name'] ??
              '')
          .toString(),
      'name': (m['name'] ?? '').toString(),
      'category': (m['category'] ?? 'Other').toString(),
      'quantity': (m['quantity'] as num?)?.toInt() ?? 0,
      'reorder_level':
          ((m['reorderLevel'] ?? m['reorder_level']) as num?)?.toInt() ?? 0,
      'condition': (m['condition'] ?? 'Good').toString(),
      'location_note':
          (m['locationNote'] ?? m['location_note'] ?? '').toString(),
      'purchase_value':
          ((m['purchaseValue'] ?? m['purchase_value']) as num?)?.toDouble() ??
              0,
      'currency': (m['currency'] ?? 'TZS').toString(),
      'sync_status': 'synced',
      'updated_at_ms':
          (m['updatedAtMs'] ?? m['updated_at_ms'] as num?)?.toInt() ?? now,
    };
    if (existing.isEmpty) {
      await db.insert(_table, {
        ...row,
        'created_at_ms':
            (m['createdAtMs'] ?? m['created_at_ms'] as num?)?.toInt() ?? now,
      });
    } else {
      final localId = existing.first['id'];
      final localSync =
          (existing.first['sync_status'] as String? ?? '').trim();
      // Keep a fresher local quantity when a stock adjustment is still pending
      // sync — otherwise pull-to-refresh / reopen restores the stale remote qty.
      if (localSync == 'pending') {
        row['quantity'] = existing.first['quantity'];
        row['sync_status'] = 'pending';
      }
      await db.update(
        _table,
        row,
        where: 'id = ?',
        whereArgs: [localId],
      );
    }
  }
}
