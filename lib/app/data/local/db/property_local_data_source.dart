import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

/// Local property row in [AppLocalDatabase.propertiesTable].
/// [propertyName] maps to column `name` (rent flow often stores suite/label here).
class PropertyRecord {
  const PropertyRecord({
    required this.id,
    required this.propertyName,
    required this.propertyType,
    required this.propertyLocation,
    required this.propertyRef,
    required this.tenants,
    required this.units,
    required this.ownerUserId,
    required this.workspaceType,
    required this.createdAtMs,
    this.rentAmount = '',
    this.rentFrequency = '',
    this.minRentalDuration = '',
    this.unitsJson = '',
    this.floorCount = 1,
    this.coverPhotoPath = '',
  });

  final int id;
  final String propertyName;
  final String propertyType;
  final String propertyLocation;
  final String propertyRef;
  final int tenants;
  final int units;
  final String ownerUserId;
  final String workspaceType;
  final int createdAtMs;
  final String rentAmount;
  final String rentFrequency;
  final String minRentalDuration;
  final String unitsJson;
  final int floorCount;
  /// Bundled asset (`images/LR-n.ext`), local file path, or remote URL.
  final String coverPhotoPath;

  /// Rent “apartment suite” field — same as [propertyName] in local schema.
  String get apartmentSuite => propertyName;

  factory PropertyRecord.fromMap(Map<String, Object?> m) {
    return PropertyRecord(
      id: m['id']! as int,
      propertyName: m['name'] as String? ?? '',
      propertyType: m['type'] as String? ?? '',
      propertyLocation: m['location'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      tenants: m['tenants'] as int? ?? 0,
      units: m['units'] as int? ?? 0,
      ownerUserId: m['owner_user_id'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      rentAmount: m['rent_amount'] as String? ?? '',
      rentFrequency: m['rent_frequency'] as String? ?? '',
      minRentalDuration: m['min_rental_duration'] as String? ?? '',
      unitsJson: m['units_json'] as String? ?? '',
      floorCount: (m['floor_count'] as num?)?.toInt() ?? 1,
      coverPhotoPath: m['cover_photo_path'] as String? ?? '',
    );
  }

  Map<String, Object?> toInsertMap() => {
        'name': propertyName,
        'type': propertyType,
        'location': propertyLocation,
        'property_ref': propertyRef,
        'tenants': tenants,
        'units': units,
        'owner_user_id': ownerUserId,
        'workspace_type': workspaceType,
        'created_at_ms': createdAtMs,
        'rent_amount': rentAmount,
        'rent_frequency': rentFrequency,
        'min_rental_duration': minRentalDuration,
        'units_json': unitsJson,
        'floor_count': floorCount,
        'cover_photo_path': coverPhotoPath,
      };
}

class PropertyLocalDataSource {
  static const _table = AppLocalDatabase.propertiesTable;
  static const _defaultChunkSize = 200;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert(PropertyRecord row) async {
    final db = await database;
    return db.insert(_table, row.toInsertMap());
  }

  Future<int> update(PropertyRecord row) async {
    final db = await database;
    return db.update(
      _table,
      row.toInsertMap(),
      where: 'id = ?',
      whereArgs: [row.id],
    );
  }

  Future<PropertyRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyRecord.fromMap(maps.first);
  }

  Future<PropertyRecord?> getByPropertyRef(String propertyRef) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'property_ref = ?',
      whereArgs: [ref],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyRecord.fromMap(maps.first);
  }

  /// Resolves `local_<id>`, `legacy_<id>`, or stored `property_ref`.
  Future<PropertyRecord?> findByHubId(String hubId) async {
    final id = hubId.trim();
    if (id.isEmpty) return null;
    const localPrefix = 'local_';
    if (id.startsWith(localPrefix)) {
      final n = int.tryParse(id.substring(localPrefix.length));
      if (n != null) return getById(n);
    }
    const legacyPrefix = 'legacy_';
    if (id.startsWith(legacyPrefix)) {
      final n = int.tryParse(id.substring(legacyPrefix.length));
      if (n != null) return getById(n);
    }
    return getByPropertyRef(id);
  }

  Future<List<PropertyRecord>> getAllNewestFirst() async {
    return getAllNewestFirstChunked();
  }

  Future<List<PropertyRecord>> getAllNewestFirstPage({
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
    return maps.map(PropertyRecord.fromMap).toList();
  }

  Future<List<PropertyRecord>> getAllNewestFirstChunked({
    int chunkSize = _defaultChunkSize,
  }) async {
    final safeChunk = chunkSize <= 0 ? _defaultChunkSize : chunkSize;
    final out = <PropertyRecord>[];
    var offset = 0;
    while (true) {
      final page = await getAllNewestFirstPage(limit: safeChunk, offset: offset);
      if (page.isEmpty) break;
      out.addAll(page);
      if (page.length < safeChunk) break;
      offset += page.length;
    }
    return out;
  }

  Future<List<PropertyRecord>> getAllByWorkspace({
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
      return maps.map(PropertyRecord.fromMap).toList();
    }
    final maps = await db.query(
      _table,
      where:
          '(workspace_type = ? OR workspace_type = "") AND (owner_user_id = ? OR owner_user_id = "")',
      whereArgs: [workspaceType, userId],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(PropertyRecord.fromMap).toList();
  }

  Future<List<PropertyRecord>> getAllVisibleNewestFirst({
    required String userId,
    String workspaceType = 'rent',
  }) async {
    return getAllVisibleNewestFirstChunked(
      userId: userId,
      workspaceType: workspaceType,
    );
  }

  Future<List<PropertyRecord>> getAllVisibleNewestFirstPage({
    required String userId,
    String workspaceType = 'rent',
    int limit = _defaultChunkSize,
    int offset = 0,
  }) async {
    final db = await database;
    final safeLimit = limit <= 0 ? _defaultChunkSize : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    if (userId.trim().isEmpty) {
      final maps = await db.query(
        _table,
        where: 'workspace_type = ? OR workspace_type = ""',
        whereArgs: [workspaceType],
        orderBy: 'created_at_ms DESC',
        limit: safeLimit,
        offset: safeOffset,
      );
      return maps.map(PropertyRecord.fromMap).toList();
    }
    final maps = await db.rawQuery(
      '''
      SELECT p.*
      FROM $_table p
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
      ORDER BY p.created_at_ms DESC
      LIMIT ? OFFSET ?
      ''',
      [workspaceType, userId, userId, workspaceType, safeLimit, safeOffset],
    );
    return maps.map(PropertyRecord.fromMap).toList();
  }

  Future<List<PropertyRecord>> getAllVisibleNewestFirstChunked({
    required String userId,
    String workspaceType = 'rent',
    int chunkSize = _defaultChunkSize,
  }) async {
    final safeChunk = chunkSize <= 0 ? _defaultChunkSize : chunkSize;
    final out = <PropertyRecord>[];
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
