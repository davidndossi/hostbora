import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class PropertyUnitRecord {
  const PropertyUnitRecord({
    required this.id,
    required this.propertyUnitRef,
    required this.propertyRef,
    required this.unitName,
    required this.status,
    required this.rentAmount,
    required this.rentFrequency,
    required this.minRentDuration,
    required this.maxGuests,
    required this.rooms,
    required this.floor,
    required this.notes,
    required this.createdAtMs,
  });

  final int id;
  final String propertyUnitRef;
  final String propertyRef;
  final String unitName;
  final String status;
  final double rentAmount;
  final String rentFrequency;
  final String minRentDuration;
  final int maxGuests;
  final int rooms;
  final int floor;
  final String notes;
  final int createdAtMs;

  factory PropertyUnitRecord.fromMap(Map<String, Object?> m) {
    return PropertyUnitRecord(
      id: m['id']! as int,
      propertyUnitRef: m['property_unit_ref'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      unitName: m['unit_name'] as String? ?? '',
      status: m['status'] as String? ?? '',
      rentAmount: (m['rent_amount'] as num?)?.toDouble() ?? 0,
      rentFrequency: m['rent_frequency'] as String? ?? '',
      minRentDuration: m['min_rent_duration'] as String? ?? '',
      maxGuests: m['max_guests'] as int? ?? 0,
      rooms: m['rooms'] as int? ?? 0,
      floor: (m['floor'] as num?)?.toInt() ?? 0,
      notes: m['notes'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }

  Map<String, Object?> toInsertMap() => {
        'property_unit_ref': propertyUnitRef,
        'property_ref': propertyRef,
        'unit_name': unitName,
        'status': status,
        'rent_amount': rentAmount,
        'rent_frequency': rentFrequency,
        'min_rent_duration': minRentDuration,
        'max_guests': maxGuests,
        'rooms': rooms,
        'floor': floor,
        'notes': notes,
        'created_at_ms': createdAtMs,
      };
}

class PropertyUnitLocalDataSource {
  static const _table = AppLocalDatabase.propertyUnitsTable;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert(PropertyUnitRecord row) async {
    final db = await database;
    return db.insert(_table, row.toInsertMap());
  }

  Future<int> update(PropertyUnitRecord row) async {
    final db = await database;
    return db.update(
      _table,
      {...row.toInsertMap(), 'id': row.id},
      where: 'id = ?',
      whereArgs: [row.id],
    );
  }

  Future<PropertyUnitRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyUnitRecord.fromMap(maps.first);
  }

  Future<PropertyUnitRecord?> getByListingId(String listingId) async {
    final key = listingId.trim();
    if (key.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'property_ref = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyUnitRecord.fromMap(maps.first);
  }

  Future<PropertyUnitRecord?> getByApartmentUnitId(String listingId) async {
    final key = listingId.trim();
    if (key.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'property_unit_ref = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyUnitRecord.fromMap(maps.first);
  }

  Future<int> deleteByPropertyRef(String propertyRef) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return 0;
    final db = await database;
    return db.delete(_table, where: 'property_ref = ?', whereArgs: [ref]);
  }

  Future<List<PropertyUnitRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(PropertyUnitRecord.fromMap).toList();
  }

  Future<List<PropertyUnitRecord>> getAllVisibleNewestFirst({
    required String userId,
    String workspaceType = 'bnb',
  }) async {
    final db = await database;
    final uid = userId.trim();
    List<Map<String, Object?>> maps;
    if (uid.isEmpty) {
      maps = await db.rawQuery(
        '''
        SELECT u.*
        FROM $_table u
        INNER JOIN ${AppLocalDatabase.propertiesTable} p
          ON p.property_ref = u.property_ref
        WHERE (p.workspace_type = ? OR p.workspace_type = '')
        ORDER BY u.created_at_ms DESC
        ''',
        [workspaceType],
      );
    } else {
      maps = await db.rawQuery(
        '''
        SELECT u.*
        FROM $_table u
        INNER JOIN ${AppLocalDatabase.propertiesTable} p
          ON p.property_ref = u.property_ref
        WHERE (p.workspace_type = ? OR p.workspace_type = '')
          AND (
            p.owner_user_id = ?
            OR p.owner_user_id = ''
            OR EXISTS (
              SELECT 1
              FROM ${AppLocalDatabase.propertyMembersTable} m
              WHERE m.property_ref = CASE
                WHEN p.property_ref IS NULL OR p.property_ref = '' THEN 'legacy_' || p.id
                ELSE p.property_ref
              END
              AND m.user_id = ?
              AND m.workspace_type = ?
            )
          )
        ORDER BY u.created_at_ms DESC
        ''',
        [workspaceType, uid, uid, workspaceType],
      );
    }
    return maps.map(PropertyUnitRecord.fromMap).toList();
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
