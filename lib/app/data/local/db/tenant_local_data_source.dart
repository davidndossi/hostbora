import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class TenantRecord {
  final int id;
  final String propertyLabel;
  /// Same hub id as [PropertyRecord.propertyRef] or `legacy_<id>`.
  final String propertyRef;
  /// Matches [ApartmentUnitDraft.unitId] in parent property [units_json].
  final String apartmentUnitId;
  final String unitLabel;
  final String tenantName;
  final String gender;
  final double rentAmountValue;
  final String rentFrequency;
  final String phoneNumber;
  final String email;
  final bool isWhatsapp;
  final String leaseStartIso;
  final String leaseEndIso;
  final String contractFilePath;
  final String contractFileName;
  final int createdAtMs;

  /// Remote backend UUID, populated after the record is synced online.
  final String backendTenantId;

  const TenantRecord({
    required this.id,
    required this.propertyLabel,
    required this.propertyRef,
    required this.apartmentUnitId,
    required this.unitLabel,
    required this.tenantName,
    required this.gender,
    required this.rentAmountValue,
    required this.rentFrequency,
    required this.phoneNumber,
    required this.email,
    required this.isWhatsapp,
    required this.leaseStartIso,
    required this.leaseEndIso,
    required this.contractFilePath,
    required this.contractFileName,
    required this.createdAtMs,
    this.backendTenantId = '',
  });

  factory TenantRecord.fromMap(Map<String, Object?> m) {
    return TenantRecord(
      id: m['id']! as int,
      propertyLabel: m['property_label'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      apartmentUnitId: m['apartment_unit_id'] as String? ?? '',
      unitLabel: m['unit_label'] as String? ?? '',
      tenantName: m['tenant_name'] as String? ?? '',
      gender: m['gender'] as String? ?? '',
      rentAmountValue:
          (m['amount_paid'] as num?)?.toDouble() ?? (m['rent_amount_value'] as num?)?.toDouble() ?? 0,
      rentFrequency: m['rent_frequency'] as String? ?? '',
      phoneNumber: m['phone_number'] as String? ?? '',
      email: m['email'] as String? ?? '',
      isWhatsapp: (m['is_whatsapp'] as int? ?? 0) == 1,
      leaseStartIso: m['lease_start_iso'] as String? ?? '',
      leaseEndIso: m['lease_end_iso'] as String? ?? '',
      contractFilePath: m['contract_file_path'] as String? ?? '',
      contractFileName: m['contract_file_name'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      backendTenantId: m['backend_tenant_id'] as String? ?? '',
    );
  }
}

class TenantLocalDataSource {
  static const _table = AppLocalDatabase.tenantTable;

  static String _normalizeWorkspace(String w) =>
      w.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await AppLocalDatabase.database;
    return _db!;
  }

  Future<int> insert({
    required String propertyLabel,
    String propertyRef = '',
    String apartmentUnitId = '',
    String unitLabel = '',
    required String tenantName,
    required String gender,
    required double rentAmountValue,
    required String rentFrequency,
    required String phoneNumber,
    required String email,
    required bool isWhatsapp,
    required String leaseStartIso,
    required String leaseEndIso,
    String contractFilePath = '',
    String contractFileName = '',
  }) async {
    final db = await database;
    return db.insert(_table, {
      'property_label': propertyLabel,
      'property_ref': propertyRef,
      'apartment_unit_id': apartmentUnitId,
      'unit_label': unitLabel,
      'tenant_name': tenantName,
      'gender': gender,
      'amount_paid': rentAmountValue,
      'rent_frequency': rentFrequency,
      'phone_number': phoneNumber,
      'email': email,
      'is_whatsapp': isWhatsapp ? 1 : 0,
      'lease_start_iso': leaseStartIso,
      'lease_end_iso': leaseEndIso,
      'contract_file_path': contractFilePath,
      'contract_file_name': contractFileName,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<TenantRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(TenantRecord.fromMap).toList();
  }

  Future<List<TenantRecord>> getAllNewestFirstByWorkspace(String ws) async {
    final db = await database;
    final w = _normalizeWorkspace(ws);
    final maps = await db.rawQuery(
      '''
      SELECT t.*
      FROM ${AppLocalDatabase.tenantTable} t
      INNER JOIN ${AppLocalDatabase.propertiesTable} p
        ON p.property_ref = t.property_ref
      WHERE lower(trim(coalesce(nullif(trim(p.workspace_type), ''), 'rent'))) = ?
      ORDER BY t.created_at_ms DESC
      ''',
      [w],
    );
    return maps.map(TenantRecord.fromMap).toList();
  }

  /// Loads tenants whose property (joined by `property_ref`) is in BnB workspace.
  Future<List<TenantRecord>> getAllForBnbWorkspaceByPropertyRefJoin() async {
    return getAllNewestFirstByWorkspace('bnb');
  }

  Future<TenantRecord?> findByNameAndProperty({
    required String tenantName,
    required String propertyLabel,
  }) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'tenant_name = ? AND property_label = ?',
      whereArgs: [tenantName, propertyLabel],
      orderBy: 'created_at_ms DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TenantRecord.fromMap(maps.first);
  }

  Future<TenantRecord?> findLatest() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC', limit: 1);
    if (maps.isEmpty) return null;
    return TenantRecord.fromMap(maps.first);
  }

  Future<TenantRecord?> findById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TenantRecord.fromMap(maps.first);
  }

  Future<void> updateLeaseEndIso({
    required int id,
    required String leaseEndIso,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {'lease_end_iso': leaseEndIso},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLeaseTerms({
    required int id,
    required double rentAmountValue,
    required String leaseStartIso,
    required String leaseEndIso,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'amount_paid': rentAmountValue,
        'lease_start_iso': leaseStartIso,
        'lease_end_iso': leaseEndIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePaymentStatus({
    required int id,
    required String paymentStatus,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {'payment_status': paymentStatus.trim().toLowerCase()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateContractFile({
    required int id,
    required String contractFilePath,
    required String contractFileName,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'contract_file_path': contractFilePath,
        'contract_file_name': contractFileName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the number of tenant rows with this [propertyRef] (trimmed),
  /// matching [PropertyRecord.propertyRef] / `local_<id>` / `legacy_<id>`.
  Future<int> countByPropertyRef(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return 0;
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE property_ref = ?',
      [r],
    );
    if (rows.isEmpty) return 0;
    final v = rows.first['c'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  /// Deletes tenant rows whose [property_ref] matches (same hub id as properties table).
  Future<int> deleteByPropertyRef(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return 0;
    final db = await database;
    return db.delete(_table, where: 'property_ref = ?', whereArgs: [r]);
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveBackendTenantId({
    required int localId,
    required String backendId,
  }) async {
    if (backendId.isEmpty) return;
    final db = await database;
    await db.update(
      _table,
      {'backend_tenant_id': backendId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> endTenancy({
    required int id,
    required String endedAtIso,
    required int endedAtMs,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'tenancy_status': 'ended',
        'ended_at_ms': endedAtMs,
        'lease_end_iso': endedAtIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TenantRecord>> getActiveTenants() async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: "tenancy_status = 'active' OR tenancy_status IS NULL OR tenancy_status = ''",
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(TenantRecord.fromMap).toList();
  }
}
