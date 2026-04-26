import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Local BnB listing row persisted for short-stay flows.
class BnBPropertyRecord {
  const BnBPropertyRecord({
    required this.id,
    required this.listingId,
    required this.apartmentUnitId,
    required this.propertyName,
    required this.propertyType,
    required this.streetAddress,
    required this.baseNightlyRate,
    required this.maxGuests,
    required this.ownerUserId,
    required this.workspaceType,
    required this.roomsJson,
    required this.createdAtMs,
  });

  final int id;
  final String listingId;
  final String apartmentUnitId;
  final String propertyName;
  final String propertyType;
  final String streetAddress;
  final double baseNightlyRate;
  final int maxGuests;
  final String ownerUserId;
  final String workspaceType;
  /// JSON array for room-level details when applicable.
  final String roomsJson;
  final int createdAtMs;

  factory BnBPropertyRecord.fromMap(Map<String, Object?> m) {
    return BnBPropertyRecord(
      id: m['id']! as int,
      listingId: m['listing_id'] as String? ?? '',
      apartmentUnitId: m['apartment_unit_id'] as String? ?? '',
      propertyName: m['property_name'] as String? ?? '',
      propertyType: m['property_type'] as String? ?? '',
      streetAddress: m['street_address'] as String? ?? '',
      baseNightlyRate: (m['base_nightly_rate'] as num?)?.toDouble() ?? 0,
      maxGuests: m['max_guests'] as int? ?? 0,
      ownerUserId: m['owner_user_id'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'bnb',
      roomsJson: m['rooms_json'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }

  Map<String, Object?> toInsertMap() => {
        'listing_id': listingId,
        'apartment_unit_id': apartmentUnitId,
        'property_name': propertyName,
        'property_type': propertyType,
        'street_address': streetAddress,
        'base_nightly_rate': baseNightlyRate,
        'max_guests': maxGuests,
        'owner_user_id': ownerUserId,
        'workspace_type': workspaceType,
        'rooms_json': roomsJson,
        'created_at_ms': createdAtMs,
      };
}

class BnBPropertyLocalDataSource {
  static const _table = AppLocalDatabase.bnbPropertiesTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert(BnBPropertyRecord row) async {
    final db = await database;
    return db.insert(_table, row.toInsertMap());
  }

  Future<int> update(BnBPropertyRecord row) async {
    final db = await database;
    return db.update(
      _table,
      row.toInsertMap(),
      where: 'id = ?',
      whereArgs: [row.id],
    );
  }

  Future<BnBPropertyRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BnBPropertyRecord.fromMap(maps.first);
  }

  Future<BnBPropertyRecord?> getByListingId(String listingId) async {
    final key = listingId.trim();
    if (key.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'listing_id = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BnBPropertyRecord.fromMap(maps.first);
  }

  Future<BnBPropertyRecord?> getByApartmentUnitId(String listingId) async {
    final key = listingId.trim();
    if (key.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'apartment_unit_id = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BnBPropertyRecord.fromMap(maps.first);
  }

  Future<List<BnBPropertyRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(BnBPropertyRecord.fromMap).toList();
  }

  Future<List<BnBPropertyRecord>> getAllVisibleNewestFirst({
    required String userId,
    String workspaceType = 'bnb',
  }) async {
    final db = await database;
    if (userId.trim().isEmpty) {
      final maps = await db.query(
        _table,
        where: 'workspace_type = ? OR workspace_type = ""',
        whereArgs: [workspaceType],
        orderBy: 'created_at_ms DESC',
      );
      return maps.map(BnBPropertyRecord.fromMap).toList();
    }
    final maps = await db.query(
      _table,
      where: '(workspace_type = ? OR workspace_type = "") AND (owner_user_id = ? OR owner_user_id = "")',
      whereArgs: [workspaceType, userId],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(BnBPropertyRecord.fromMap).toList();
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
