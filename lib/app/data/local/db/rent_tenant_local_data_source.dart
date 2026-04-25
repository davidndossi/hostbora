import 'package:sqflite/sqflite.dart';

import 'app_local_database.dart';

class RentTenantRecord {
  const RentTenantRecord({
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
  });

  final int id;
  final String propertyLabel;
  /// Same hub id as [RentPropertyRecord.propertyRef] or `legacy_<id>`.
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

  factory RentTenantRecord.fromMap(Map<String, Object?> m) {
    return RentTenantRecord(
      id: m['id']! as int,
      propertyLabel: m['property_label'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      apartmentUnitId: m['apartment_unit_id'] as String? ?? '',
      unitLabel: m['unit_label'] as String? ?? '',
      tenantName: m['tenant_name'] as String? ?? '',
      gender: m['gender'] as String? ?? '',
      rentAmountValue: (m['rent_amount_value'] as num?)?.toDouble() ?? 0,
      rentFrequency: m['rent_frequency'] as String? ?? '',
      phoneNumber: m['phone_number'] as String? ?? '',
      email: m['email'] as String? ?? '',
      isWhatsapp: (m['is_whatsapp'] as int? ?? 0) == 1,
      leaseStartIso: m['lease_start_iso'] as String? ?? '',
      leaseEndIso: m['lease_end_iso'] as String? ?? '',
      contractFilePath: m['contract_file_path'] as String? ?? '',
      contractFileName: m['contract_file_name'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
    );
  }
}

class RentTenantLocalDataSource {
  static const _table = AppLocalDatabase.rentTenantTable;

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
      'rent_amount_value': rentAmountValue,
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

  Future<List<RentTenantRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentTenantRecord.fromMap).toList();
  }

  Future<RentTenantRecord?> findByNameAndProperty({
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
    return RentTenantRecord.fromMap(maps.first);
  }

  Future<RentTenantRecord?> findLatest() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC', limit: 1);
    if (maps.isEmpty) return null;
    return RentTenantRecord.fromMap(maps.first);
  }

  Future<RentTenantRecord?> findById(int id) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RentTenantRecord.fromMap(maps.first);
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
        'rent_amount_value': rentAmountValue,
        'lease_start_iso': leaseStartIso,
        'lease_end_iso': leaseEndIso,
      },
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
}
