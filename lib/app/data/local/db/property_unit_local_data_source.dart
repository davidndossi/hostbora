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
    required this.operationMode,
    required this.notes,
    required this.createdAtMs,
    this.rentCurrency = 'TZS',
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
  final String operationMode;
  final String notes;
  final int createdAtMs;

  /// ISO 4217 currency code for [rentAmount]. Defaults to base currency (TZS).
  /// Always store the original contract currency; convert at display time.
  final String rentCurrency;

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
      operationMode: _normalizeOperationMode(
        m['operation_mode'] as String? ?? '',
      ),
      notes: m['notes'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      rentCurrency: _normCurrency(m['rent_currency'] as String?),
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
    'operation_mode': _normalizeOperationMode(operationMode),
    'notes': notes,
    'created_at_ms': createdAtMs,
    'rent_currency': rentCurrency.trim().toUpperCase().isEmpty ? 'TZS' : rentCurrency.trim().toUpperCase(),
  };

  static String _normCurrency(String? raw) {
    final v = raw?.trim().toUpperCase() ?? '';
    return v.isEmpty ? 'TZS' : v;
  }

  static String _normalizeOperationMode(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'rent' ? 'rent' : 'bnb';
  }
}

class PropertyUnitLocalDataSource {
  static const _table = AppLocalDatabase.propertyUnitsTable;
  static const _defaultChunkSize = 200;

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
    return getAllNewestFirstChunked();
  }

  Future<List<PropertyUnitRecord>> getAllNewestFirstPage({
    int limit = _defaultChunkSize,
    int offset = 0,
  }) async {
    final db = await database;
    final safeLimit = limit <= 0 ? _defaultChunkSize : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    final maps = await db.query(
      _table,
      orderBy: 'created_at_ms DESC',
      limit: safeLimit,
      offset: safeOffset,
    );
    return maps.map(PropertyUnitRecord.fromMap).toList();
  }

  Future<List<PropertyUnitRecord>> getAllNewestFirstChunked({
    int chunkSize = _defaultChunkSize,
  }) async {
    final safeChunk = chunkSize <= 0 ? _defaultChunkSize : chunkSize;
    final out = <PropertyUnitRecord>[];
    var offset = 0;
    while (true) {
      final page = await getAllNewestFirstPage(
        limit: safeChunk,
        offset: offset,
      );
      if (page.isEmpty) break;
      out.addAll(page);
      if (page.length < safeChunk) break;
      offset += page.length;
    }
    return out;
  }

  Future<List<PropertyUnitRecord>> getAllByPropertyRefNewestFirstPage({
    required String propertyRef,
    int limit = _defaultChunkSize,
    int offset = 0,
  }) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return const [];
    final db = await database;
    final safeLimit = limit <= 0 ? _defaultChunkSize : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    final maps = await db.query(
      _table,
      where: 'property_ref = ?',
      whereArgs: [ref],
      orderBy: 'created_at_ms DESC',
      limit: safeLimit,
      offset: safeOffset,
    );
    return maps.map(PropertyUnitRecord.fromMap).toList();
  }

  Future<List<PropertyUnitRecord>> getAllByPropertyRefNewestFirstChunked({
    required String propertyRef,
    int chunkSize = _defaultChunkSize,
  }) async {
    final safeChunk = chunkSize <= 0 ? _defaultChunkSize : chunkSize;
    final out = <PropertyUnitRecord>[];
    var offset = 0;
    while (true) {
      final page = await getAllByPropertyRefNewestFirstPage(
        propertyRef: propertyRef,
        limit: safeChunk,
        offset: offset,
      );
      if (page.isEmpty) break;
      out.addAll(page);
      if (page.length < safeChunk) break;
      offset += page.length;
    }
    return out;
  }

  Future<List<PropertyUnitRecord>> getAllVisibleNewestFirst({
    required String userId,
    String workspaceType = 'bnb',
  }) async {
    return getAllVisibleNewestFirstChunked(
      userId: userId,
      workspaceType: workspaceType,
    );
  }

  Future<List<PropertyUnitRecord>> getAllVisibleNewestFirstPage({
    required String userId,
    String workspaceType = 'bnb',
    int limit = _defaultChunkSize,
    int offset = 0,
  }) async {
    final db = await database;
    final uid = userId.trim();
    final safeLimit = limit <= 0 ? _defaultChunkSize : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    List<Map<String, Object?>> maps;
    if (uid.isEmpty) {
      maps = await db.rawQuery(
        '''
        SELECT u.*
        FROM $_table u
        INNER JOIN ${AppLocalDatabase.propertiesTable} p
          ON p.property_ref = u.property_ref
        WHERE (p.workspace_type = ? OR p.workspace_type = ? OR p.workspace_type = '')
          AND (
            p.workspace_type != ?
            OR u.operation_mode = ?
            OR u.operation_mode = ''
          )
        ORDER BY u.created_at_ms DESC
        LIMIT ? OFFSET ?
        ''',
        [workspaceType, 'both', 'both', workspaceType, safeLimit, safeOffset],
      );
    } else {
      maps = await db.rawQuery(
        '''
        SELECT u.*
        FROM $_table u
        INNER JOIN ${AppLocalDatabase.propertiesTable} p
          ON p.property_ref = u.property_ref
        WHERE (p.workspace_type = ? OR p.workspace_type = ? OR p.workspace_type = '')
          AND (
            p.workspace_type != ?
            OR u.operation_mode = ?
            OR u.operation_mode = ''
          )
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
              AND (m.workspace_type = ? OR m.workspace_type = ?)
            )
          )
        ORDER BY u.created_at_ms DESC
        LIMIT ? OFFSET ?
        ''',
        [
          workspaceType,
          'both',
          'both',
          workspaceType,
          uid,
          uid,
          workspaceType,
          'both',
          safeLimit,
          safeOffset,
        ],
      );
    }
    return maps.map(PropertyUnitRecord.fromMap).toList();
  }

  Future<List<PropertyUnitRecord>> getAllVisibleNewestFirstChunked({
    required String userId,
    String workspaceType = 'bnb',
    int chunkSize = _defaultChunkSize,
  }) async {
    final safeChunk = chunkSize <= 0 ? _defaultChunkSize : chunkSize;
    final out = <PropertyUnitRecord>[];
    var offset = 0;
    while (true) {
      final page = await getAllVisibleNewestFirstPage(
        userId: userId,
        workspaceType: workspaceType,
        limit: safeChunk,
        offset: offset,
      );
      if (page.isEmpty) break;
      out.addAll(page);
      if (page.length < safeChunk) break;
      offset += page.length;
    }
    return out;
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
