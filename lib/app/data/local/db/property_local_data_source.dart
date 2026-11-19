import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/utils/sync_freshness.dart';
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
    this.listingStatus = listingStatusActive,
    this.updatedAtMs = 0,
  });

  static const listingStatusActive = 'ACTIVE';
  static const listingStatusDraft = 'DRAFT';
  static const listingStatusArchived = 'ARCHIVED';

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

  /// Listing lifecycle: [listingStatusActive], [listingStatusDraft], or [listingStatusArchived].
  final String listingStatus;

  /// Last local or applied remote edit. `0` means "use [createdAtMs]".
  final int updatedAtMs;

  /// Rent “apartment suite” field — same as [propertyName] in local schema.
  String get apartmentSuite => propertyName;

  /// Property workspace comes from `workspace_type` only.
  /// Unit fields (`listingMode`, `operationMode`) default to bnb and must
  /// not overwrite a rent property during remote sync.
  static String normalizeWorkspaceType(String? raw, {String fallback = ''}) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    if (value == 'rent' || value == 'bnb' || value == 'both') return value;
    return fallback;
  }

  static String? workspaceFromApiMap(Map<String, dynamic> m) {
    for (final key in ['workspace_type', 'workspaceType']) {
      final value = normalizeWorkspaceType(m[key]?.toString());
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// Reads a properties-table value. Keys are the SQL column and its
  /// Jackson camelCase only — no listings-table aliases.
  static String remoteText(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final value = m[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String remoteName(Map<String, dynamic> m) =>
      remoteText(m, const ['name']);

  static String remoteLocation(Map<String, dynamic> m) =>
      remoteText(m, const ['location']);

  static String remoteType(Map<String, dynamic> m) =>
      remoteText(m, const ['type']);

  static String remoteRef(Map<String, dynamic> m) =>
      remoteText(m, const ['property_ref', 'propertyRef']);

  static String remoteOwner(Map<String, dynamic> m) =>
      remoteText(m, const ['owner_user_id', 'ownerUserId']);

  static String remoteRentAmount(Map<String, dynamic> m) =>
      remoteText(m, const ['rent_amount', 'rentAmount']);

  static String remoteRentFrequency(Map<String, dynamic> m) =>
      remoteText(m, const ['rent_frequency', 'rentFrequency']);

  static String remoteMinDuration(Map<String, dynamic> m) =>
      remoteText(m, const ['min_rental_duration', 'minRentalDuration']);

  static String remoteCoverPhoto(Map<String, dynamic> m) =>
      remoteText(m, const ['cover_photo_path', 'coverPhotoPath']);

  static String remoteUnitsJson(Map<String, dynamic> m) =>
      remoteText(m, const ['units_json', 'unitsJson']);

  static String normalizeListingStatus(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    if (s == 'DRAFT') return listingStatusDraft;
    if (s == 'ARCHIVED' || s == 'ARCHIVE') return listingStatusArchived;
    return listingStatusActive;
  }

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
      listingStatus: normalizeListingStatus(m['listing_status'] as String?),
      updatedAtMs: (m['updated_at_ms'] as num?)?.toInt() ?? 0,
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
    'listing_status': normalizeListingStatus(listingStatus),
  };

  PropertyRecord copyWith({
    int? id,
    String? propertyName,
    String? propertyType,
    String? propertyLocation,
    String? propertyRef,
    int? tenants,
    int? units,
    String? ownerUserId,
    String? workspaceType,
    int? createdAtMs,
    String? rentAmount,
    String? rentFrequency,
    String? minRentalDuration,
    String? unitsJson,
    int? floorCount,
    String? coverPhotoPath,
    String? listingStatus,
    int? updatedAtMs,
  }) {
    return PropertyRecord(
      id: id ?? this.id,
      propertyName: propertyName ?? this.propertyName,
      propertyType: propertyType ?? this.propertyType,
      propertyLocation: propertyLocation ?? this.propertyLocation,
      propertyRef: propertyRef ?? this.propertyRef,
      tenants: tenants ?? this.tenants,
      units: units ?? this.units,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      workspaceType: workspaceType ?? this.workspaceType,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rentAmount: rentAmount ?? this.rentAmount,
      rentFrequency: rentFrequency ?? this.rentFrequency,
      minRentalDuration: minRentalDuration ?? this.minRentalDuration,
      unitsJson: unitsJson ?? this.unitsJson,
      floorCount: floorCount ?? this.floorCount,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      listingStatus: listingStatus != null
          ? normalizeListingStatus(listingStatus)
          : this.listingStatus,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class PropertyLocalDataSource {
  static const _table = AppLocalDatabase.propertiesTable;
  static const _defaultChunkSize = 200;

  static final List<void Function()> _onChanged = <void Function()>[];

  static void addOnChangedListener(void Function() listener) {
    _onChanged.add(listener);
  }

  static void removeOnChangedListener(void Function() listener) {
    _onChanged.remove(listener);
  }

  /// Notifies badge / list listeners after local property rows change.
  static void notifyChanged() {
    final listeners = List<void Function()>.from(_onChanged);
    for (final listener in listeners) {
      listener();
    }
  }

  Future<Database> get database => AppLocalDatabase.database;

  Future<int> insert(PropertyRecord row) async {
    final db = await database;
    final map = row.toInsertMap();
    map['updated_at_ms'] = row.updatedAtMs > 0
        ? row.updatedAtMs
        : (row.createdAtMs > 0
              ? row.createdAtMs
              : DateTime.now().millisecondsSinceEpoch);
    final id = await db.insert(_table, map);
    notifyChanged();
    return id;
  }

  Future<int> update(PropertyRecord row, {int? updatedAtMs}) async {
    final db = await database;
    final map = row.toInsertMap();
    map['updated_at_ms'] = updatedAtMs ?? DateTime.now().millisecondsSinceEpoch;
    final n = await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [row.id],
    );
    notifyChanged();
    return n;
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

  Future<List<PropertyRecord>> fetchAll({required String userId}) async {
    final db = await database;
    if (userId.trim().isEmpty) {
      final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
      return maps.map(PropertyRecord.fromMap).toList();
    }
    final maps = await db.query(
      _table,
      where: 'owner_user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(PropertyRecord.fromMap).toList();
  }

  /// Owner + member properties across every workspace. Cheap COUNT for the
  /// bottom-nav badge; does not load rows.
  Future<int> countVisibleForUser(String userId) async {
    final db = await database;
    final uid = userId.trim();
    if (uid.isEmpty) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
      return Sqflite.firstIntValue(rows) ?? 0;
    }
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM $_table p
      WHERE (
        p.owner_user_id = ?
        OR EXISTS (
          SELECT 1
          FROM ${AppLocalDatabase.propertyMembersTable} m
          WHERE m.property_ref = CASE
            WHEN p.property_ref IS NULL OR p.property_ref = '' THEN 'legacy_' || p.id
            ELSE p.property_ref
          END
          AND m.user_id = ?
        )
      )
      ''',
      [uid, uid],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
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

  Future<List<PropertyRecord>> getAllByWorkspace({
    required String userId,
    String workspaceType = 'bnb',
  }) async {
    final db = await database;
    if (userId.trim().isEmpty) {
      final maps = await db.query(
        _table,
        where:
            'workspace_type = ? OR workspace_type = ? OR workspace_type = ""',
        whereArgs: [workspaceType, 'both'],
        orderBy: 'created_at_ms DESC',
      );
      return maps.map(PropertyRecord.fromMap).toList();
    }
    final maps = await db.query(
      _table,
      where:
          '(workspace_type = ? OR workspace_type = ? OR workspace_type = "") AND owner_user_id = ?',
      whereArgs: [workspaceType, 'both', userId],
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
    final ws = workspaceType.trim().toLowerCase();
    // Empty / "all" means every workspace (bnb, rent, both, unset).
    final allWorkspaces = ws.isEmpty || ws == 'all';

    if (userId.trim().isEmpty) {
      final maps = allWorkspaces
          ? await db.query(
              _table,
              orderBy: 'created_at_ms DESC',
              limit: safeLimit,
              offset: safeOffset,
            )
          : await db.query(
              _table,
              where:
                  'workspace_type = ? OR workspace_type = ? OR workspace_type = ""',
              whereArgs: [ws, 'both'],
              orderBy: 'created_at_ms DESC',
              limit: safeLimit,
              offset: safeOffset,
            );
      return maps.map(PropertyRecord.fromMap).toList();
    }

    if (allWorkspaces) {
      final maps = await db.rawQuery(
        '''
        SELECT p.*
        FROM $_table p
        WHERE (
          p.owner_user_id = ?
          OR EXISTS (
            SELECT 1
            FROM ${AppLocalDatabase.propertyMembersTable} m
            WHERE m.property_ref = CASE
              WHEN p.property_ref IS NULL OR p.property_ref = '' THEN 'legacy_' || p.id
              ELSE p.property_ref
            END
            AND m.user_id = ?
          )
        )
        ORDER BY p.created_at_ms DESC
        LIMIT ? OFFSET ?
        ''',
        [userId, userId, safeLimit, safeOffset],
      );
      return maps.map(PropertyRecord.fromMap).toList();
    }

    final maps = await db.rawQuery(
      '''
      SELECT p.*
      FROM $_table p
      WHERE (p.workspace_type = ? OR p.workspace_type = ? OR p.workspace_type = '')
        AND (
          p.owner_user_id = ?
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
      ORDER BY p.created_at_ms DESC
      LIMIT ? OFFSET ?
      ''',
      [ws, 'both', userId, userId, ws, 'both', safeLimit, safeOffset],
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
    notifyChanged();
  }

  Future<PropertyRecord> upsertFromRemote(PropertyRecord row) async {
    final ref = row.propertyRef.trim();
    PropertyRecord? existing;
    if (ref.isNotEmpty) {
      existing = await getByPropertyRef(ref);
    }
    if (existing != null) {
      if (SyncFreshness.phoneIsNewer(
        localUpdatedMs: existing.updatedAtMs,
        localCreatedMs: existing.createdAtMs,
        remoteUpdatedMs: row.updatedAtMs,
      )) {
        return existing;
      }
      final remoteJson = row.unitsJson.trim();
      final localJson = existing.unitsJson.trim();
      // An empty server units payload must not wipe units that exist only
      // on the phone. A non-empty server payload replaces them when the
      // server copy is the newer edit.
      final keepLocalUnits = remoteJson.isEmpty && localJson.isNotEmpty;
      final appliedUpdated = row.updatedAtMs > 0
          ? row.updatedAtMs
          : (existing.updatedAtMs > 0
                ? existing.updatedAtMs
                : existing.createdAtMs);

      final merged = PropertyRecord(
        id: existing.id,
        propertyName: row.propertyName.isNotEmpty
            ? row.propertyName
            : existing.propertyName,
        propertyType: row.propertyType.isNotEmpty
            ? row.propertyType
            : existing.propertyType,
        propertyLocation: row.propertyLocation.isNotEmpty
            ? row.propertyLocation
            : existing.propertyLocation,
        propertyRef: ref.isNotEmpty ? ref : existing.propertyRef,
        tenants: row.tenants > 0 ? row.tenants : existing.tenants,
        units: keepLocalUnits
            ? (existing.units > 0
                  ? existing.units
                  : _countUnitsInJson(localJson))
            : (row.units > 0 ? row.units : existing.units),
        ownerUserId: row.ownerUserId.isNotEmpty
            ? row.ownerUserId
            : existing.ownerUserId,
        workspaceType: row.workspaceType.isNotEmpty
            ? row.workspaceType
            : existing.workspaceType,
        createdAtMs: row.createdAtMs > 0
            ? row.createdAtMs
            : existing.createdAtMs,
        rentAmount: row.rentAmount.isNotEmpty
            ? row.rentAmount
            : existing.rentAmount,
        rentFrequency: row.rentFrequency.isNotEmpty
            ? row.rentFrequency
            : existing.rentFrequency,
        minRentalDuration: row.minRentalDuration.isNotEmpty
            ? row.minRentalDuration
            : existing.minRentalDuration,
        unitsJson: keepLocalUnits ? existing.unitsJson : row.unitsJson,
        floorCount: row.floorCount > 0 ? row.floorCount : existing.floorCount,
        coverPhotoPath: row.coverPhotoPath.isNotEmpty
            ? row.coverPhotoPath
            : existing.coverPhotoPath,
        listingStatus: row.listingStatus.trim().isEmpty
            ? existing.listingStatus
            : PropertyRecord.normalizeListingStatus(row.listingStatus),
        updatedAtMs: appliedUpdated,
      );
      await update(merged, updatedAtMs: appliedUpdated);
      return merged;
    }
    final toInsert = row.workspaceType.trim().isEmpty
        ? row.copyWith(workspaceType: 'rent')
        : row;
    final newId = await insert(toInsert);
    return PropertyRecord(
      id: newId,
      propertyName: toInsert.propertyName,
      propertyType: row.propertyType,
      propertyLocation: row.propertyLocation,
      propertyRef: row.propertyRef,
      tenants: row.tenants,
      units: row.units,
      ownerUserId: row.ownerUserId,
      workspaceType: toInsert.workspaceType,
      createdAtMs: row.createdAtMs,
      rentAmount: row.rentAmount,
      rentFrequency: row.rentFrequency,
      minRentalDuration: row.minRentalDuration,
      unitsJson: row.unitsJson,
      floorCount: row.floorCount,
      coverPhotoPath: row.coverPhotoPath,
      listingStatus: row.listingStatus,
      updatedAtMs: row.updatedAtMs > 0 ? row.updatedAtMs : row.createdAtMs,
    );
  }

  Future<void> updateListingStatus({
    required int id,
    required String listingStatus,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'listing_status': PropertyRecord.normalizeListingStatus(listingStatus),
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyChanged();
  }

  Future<PropertyRecord?> updateListingStatusByRef({
    required String propertyRef,
    required String listingStatus,
  }) async {
    final existing = await getByPropertyRef(propertyRef.trim());
    if (existing == null) return null;
    final updated = existing.copyWith(listingStatus: listingStatus);
    await update(updated);
    return updated;
  }

  /// Count named units in a units_json payload (avoids importing PropertyUnitCount).
  static int _countUnitsInJson(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text == '[]' || text == 'null') return 0;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return 0;
      var count = 0;
      for (final item in decoded) {
        if (item is Map) {
          final name = (item['unitName'] ?? item['name'] ?? '')
              .toString()
              .trim();
          if (name.isEmpty) continue;
        }
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}
