import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/sync_freshness.dart';
import '../preference/preference_manager.dart';
import '../service/local_account_data_reset.dart';
import 'app_local_database.dart';
import 'property_local_data_source.dart';

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

  /// ISO 4217 currency code for [rentAmountValue]. Always the contract currency; convert at display time.
  final String rentCurrency;

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
    this.rentCurrency = 'TZS',
    this.tenancyStatus = 'active',
    this.updatedAtMs = 0,
  });

  /// `active` while the tenant is current. `ended` after a replacement or end tenancy.
  final String tenancyStatus;

  /// Last local or applied remote edit. `0` means "use [createdAtMs]".
  final int updatedAtMs;

  bool get isActiveTenancy {
    final status = tenancyStatus.trim().toLowerCase();
    return status.isEmpty || status == 'active';
  }

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
      rentCurrency: _normCurrency(m['rent_currency'] as String?),
      tenancyStatus: m['tenancy_status'] as String? ?? 'active',
      updatedAtMs: (m['updated_at_ms'] as num?)?.toInt() ?? 0,
    );
  }

  static String _normCurrency(String? raw) {
    final v = raw?.trim().toUpperCase() ?? '';
    return v.isEmpty ? 'TZS' : v;
  }
}

class TenantLocalDataSource {
  static const _table = AppLocalDatabase.tenantTable;

  static String _normalizeWorkspace(String w) =>
      w.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';

  Future<Database> get database => AppLocalDatabase.database;

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
    String rentCurrency = 'TZS',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
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
      'rent_currency': rentCurrency.trim().toUpperCase().isEmpty ? 'TZS' : rentCurrency.trim().toUpperCase(),
      'created_at_ms': now,
      'updated_at_ms': now,
    });
  }

  Future<List<TenantRecord>> getAllNewestFirst() async {
    await _isolateSignedInAccount();
    final db = await database;
    final userId = await _signedInUserId();
    if (userId.isEmpty) return const [];
    final props = await _propertiesForUser(db, userId);
    if (props.isEmpty) return const [];
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps
        .map(TenantRecord.fromMap)
        .where((tenant) => props.any((p) => _tenantMatchesProperty(tenant, p)))
        .toList();
  }

  /// Tenants linked to properties in [ws] (`rent` / `bnb`).
  ///
  /// Matches `property_ref`, `local_<id>` / `legacy_<id>`, and property label
  /// aliases. Includes properties with workspace `both`.
  Future<List<TenantRecord>> getAllNewestFirstByWorkspace(String ws) async {
    final w = _normalizeWorkspace(ws);
    final tenants = await getAllNewestFirst();
    if (tenants.isEmpty) return const [];

    final db = await database;
    final userId = await _signedInUserId();
    final propMaps = userId.isEmpty
        ? const <Map<String, Object?>>[]
        : await _propertyMapsForUser(db, userId);
    final props = <PropertyRecord>[];
    for (final m in propMaps) {
      final p = PropertyRecord.fromMap(m);
      final pws = p.workspaceType.trim().toLowerCase();
      final normalized = pws.isEmpty ? 'rent' : pws;
      if (normalized == w || normalized == 'both') {
        props.add(p);
      }
    }
    if (props.isEmpty) return const [];

    final out = <TenantRecord>[];
    final seen = <int>{};
    for (final t in tenants) {
      for (final p in props) {
        if (_tenantMatchesProperty(t, p) && seen.add(t.id)) {
          out.add(t);
          break;
        }
      }
    }
    return out;
  }

  Future<void> _isolateSignedInAccount() async {
    if (!Get.isRegistered<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    )) {
      return;
    }
    await LocalAccountDataReset.alignToUser(
      Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
    );
  }

  Future<String> _signedInUserId() async {
    if (!Get.isRegistered<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    )) {
      return '';
    }
    try {
      final user = await Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ).getUser();
      return user.id?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<List<PropertyRecord>> _propertiesForUser(
    Database db,
    String userId,
  ) async {
    final maps = await _propertyMapsForUser(db, userId);
    return maps.map(PropertyRecord.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> _propertyMapsForUser(
    Database db,
    String userId,
  ) async {
    return db.rawQuery(
      '''
      SELECT p.*
      FROM ${AppLocalDatabase.propertiesTable} p
      WHERE p.owner_user_id = ?
         OR EXISTS (
           SELECT 1
           FROM ${AppLocalDatabase.propertyMembersTable} m
           WHERE m.user_id = ?
             AND m.property_ref = CASE
               WHEN p.property_ref IS NULL OR p.property_ref = '' THEN 'legacy_' || p.id
               ELSE p.property_ref
             END
         )
      ''',
      [userId, userId],
    );
  }

  static bool _tenantMatchesProperty(TenantRecord t, PropertyRecord p) {
    final ref = t.propertyRef.trim();
    final pRef = p.propertyRef.trim();
    if (ref.isNotEmpty) {
      if (pRef.isNotEmpty && ref == pRef) return true;
      if (ref == 'legacy_${p.id}' || ref == 'local_${p.id}') return true;
    }
    final label = t.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final loc = p.propertyLocation.trim().toLowerCase();
    final name = p.propertyName.trim().toLowerCase();
    final lineLocName =
        loc.isNotEmpty && name.isNotEmpty ? '$loc · $name' : '';
    final lineNameLoc =
        loc.isNotEmpty && name.isNotEmpty ? '$name · $loc' : '';
    final single = loc.isNotEmpty ? loc : name;
    if (label == lineLocName ||
        label == lineNameLoc ||
        label == name ||
        label == loc ||
        (single.isNotEmpty && label == single)) {
      return true;
    }
    if (name.isNotEmpty && label.contains(name)) return true;
    if (loc.isNotEmpty && label.contains(loc)) return true;
    return false;
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
      {
        'lease_end_iso': leaseEndIso,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTenantDetails({
    required int id,
    required String tenantName,
    required String phoneNumber,
    required String email,
    required double rentAmountValue,
    required String leaseStartIso,
    required String leaseEndIso,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'tenant_name': tenantName.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
        'amount_paid': rentAmountValue,
        'lease_start_iso': leaseStartIso,
        'lease_end_iso': leaseEndIso,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
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
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
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
      {
        'payment_status': paymentStatus.trim().toLowerCase(),
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
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
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tenant rows for this listing hub id, including `local_` / `legacy_` aliases.
  Future<List<TenantRecord>> listByPropertyRef(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return const [];
    final aliases = await _propertyRefAliases(r);
    if (aliases.isEmpty) return const [];
    final db = await database;
    final placeholders = List.filled(aliases.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM $_table WHERE property_ref IN ($placeholders) ORDER BY created_at_ms DESC',
      aliases.toList(),
    );
    return rows.map(TenantRecord.fromMap).toList();
  }

  /// Returns the number of current tenants for this listing hub id.
  ///
  /// Counts rows whose `property_ref` matches [propertyRef] or any alias
  /// (`local_<id>`, `legacy_<id>`, or the property's stored hub UUID).
  /// Ended tenancies stay in the table after a replacement, so they are
  /// left out of this count.
  Future<int> countByPropertyRef(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return 0;
    final aliases = await _propertyRefAliases(r);
    if (aliases.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(aliases.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE property_ref IN ($placeholders) '
      "AND (tenancy_status IS NULL OR tenancy_status = '' OR tenancy_status = 'active')",
      aliases.toList(),
    );
    if (rows.isEmpty) return 0;
    final v = rows.first['c'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<Set<String>> _propertyRefAliases(String propertyRef) async {
    final r = propertyRef.trim();
    if (r.isEmpty) return const {};
    final aliases = <String>{r};
    final db = await database;

    int? localId;
    if (r.startsWith('local_')) {
      localId = int.tryParse(r.substring('local_'.length));
    } else if (r.startsWith('legacy_')) {
      localId = int.tryParse(r.substring('legacy_'.length));
    }

    if (localId != null) {
      aliases.add('local_$localId');
      aliases.add('legacy_$localId');
      final props = await db.query(
        AppLocalDatabase.propertiesTable,
        columns: ['property_ref'],
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (props.isNotEmpty) {
        final hub = props.first['property_ref']?.toString().trim() ?? '';
        if (hub.isNotEmpty) aliases.add(hub);
      }
      return aliases;
    }

    final props = await db.query(
      AppLocalDatabase.propertiesTable,
      columns: ['id', 'property_ref'],
      where: 'property_ref = ?',
      whereArgs: [r],
      limit: 1,
    );
    if (props.isNotEmpty) {
      final id = props.first['id'] as int?;
      if (id != null) {
        aliases.add('local_$id');
        aliases.add('legacy_$id');
      }
    }
    return aliases;
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

  Future<TenantRecord?> findByBackendTenantId(String backendId) async {
    final id = backendId.trim();
    if (id.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'backend_tenant_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TenantRecord.fromMap(maps.first);
  }

  Future<TenantRecord?> findByPhoneAndPropertyRef({
    required String phoneNumber,
    required String propertyRef,
  }) async {
    final phone = phoneNumber.trim();
    final ref = propertyRef.trim();
    if (phone.isEmpty || ref.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'phone_number = ? AND property_ref = ?',
      whereArgs: [phone, ref],
      orderBy: 'created_at_ms DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TenantRecord.fromMap(maps.first);
  }

  /// Upsert a tenant row pulled from the backend.
  Future<TenantRecord> upsertFromRemote({
    required String backendTenantId,
    required String tenantName,
    required String phoneNumber,
    required String email,
    required String propertyRef,
    required String propertyLabel,
    required String apartmentUnitId,
    required String unitLabel,
    required double rentAmountValue,
    required String rentFrequency,
    required String leaseStartIso,
    required String leaseEndIso,
    required String rentCurrency,
    int remoteUpdatedAtMs = 0,
    String tenancyStatus = '',
  }) async {
    final backendId = backendTenantId.trim();
    final existing = backendId.isNotEmpty
        ? await findByBackendTenantId(backendId)
        : null;
    final byPhone = existing ??
        await findByPhoneAndPropertyRef(
          phoneNumber: phoneNumber,
          propertyRef: propertyRef,
        );
    final byName = byPhone ??
        (tenantName.trim().isEmpty
            ? null
            : await findByNameAndProperty(
                tenantName: tenantName.trim(),
                propertyLabel: propertyLabel.trim().isNotEmpty
                    ? propertyLabel.trim()
                    : propertyRef.trim(),
              ));

    if (byName != null &&
        SyncFreshness.phoneIsNewer(
          localUpdatedMs: byName.updatedAtMs,
          localCreatedMs: byName.createdAtMs,
          remoteUpdatedMs: remoteUpdatedAtMs,
        )) {
      if (backendId.isNotEmpty && byName.backendTenantId.trim().isEmpty) {
        await saveBackendTenantId(localId: byName.id, backendId: backendId);
        return (await findById(byName.id))!;
      }
      return byName;
    }

    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final appliedUpdated = remoteUpdatedAtMs > 0
        ? remoteUpdatedAtMs
        : (byName != null
            ? (byName.updatedAtMs > 0 ? byName.updatedAtMs : byName.createdAtMs)
            : now);
    final incomingStatus = tenancyStatus.trim().toLowerCase();
    final data = <String, Object?>{
      'property_label': propertyLabel,
      'property_ref': propertyRef,
      'apartment_unit_id': apartmentUnitId,
      'unit_label': unitLabel,
      'tenant_name': tenantName,
      'gender': byName?.gender ?? '',
      'amount_paid': rentAmountValue,
      'rent_frequency': rentFrequency,
      'phone_number': phoneNumber,
      'email': email,
      'is_whatsapp': byName?.isWhatsapp == true ? 1 : 0,
      'lease_start_iso': leaseStartIso,
      'lease_end_iso': leaseEndIso,
      'contract_file_path': byName?.contractFilePath ?? '',
      'contract_file_name': byName?.contractFileName ?? '',
      'rent_currency': TenantRecord._normCurrency(rentCurrency),
      'backend_tenant_id': backendId.isNotEmpty
          ? backendId
          : (byName?.backendTenantId ?? ''),
      'created_at_ms': byName?.createdAtMs ?? now,
      'updated_at_ms': appliedUpdated,
    };
    if (incomingStatus == 'active' || incomingStatus == 'ended') {
      data['tenancy_status'] = incomingStatus;
    }

    if (byName != null) {
      if (leaseEndIso.trim().isEmpty) {
        data['lease_end_iso'] = byName.leaseEndIso;
      }
      if (tenantName.trim().isEmpty) data['tenant_name'] = byName.tenantName;
      if (phoneNumber.trim().isEmpty) data['phone_number'] = byName.phoneNumber;
      if (email.trim().isEmpty) data['email'] = byName.email;
      if (rentAmountValue <= 0) data['amount_paid'] = byName.rentAmountValue;
      if (unitLabel.trim().isEmpty) data['unit_label'] = byName.unitLabel;
      if (apartmentUnitId.trim().isEmpty) {
        data['apartment_unit_id'] = byName.apartmentUnitId;
      }
      if (leaseStartIso.trim().isEmpty &&
          byName.leaseStartIso.trim().isNotEmpty) {
        data['lease_start_iso'] = byName.leaseStartIso;
      }
      final incomingLabel = propertyLabel.trim();
      final localLabel = byName.propertyLabel.trim();
      if (_looksLikePropertyRef(incomingLabel) &&
          localLabel.isNotEmpty &&
          !_looksLikePropertyRef(localLabel)) {
        data['property_label'] = localLabel;
      }
      await db.update(_table, data, where: 'id = ?', whereArgs: [byName.id]);
      return (await findById(byName.id))!;
    }
    final newId = await db.insert(_table, data);
    return (await findById(newId))!;
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
        'updated_at_ms': endedAtMs > 0
            ? endedAtMs
            : DateTime.now().millisecondsSinceEpoch,
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

  static bool _looksLikePropertyRef(String value) {
    final v = value.trim();
    if (v.startsWith('local_') ||
        v.startsWith('legacy_') ||
        v.startsWith('remote_')) {
      return true;
    }
    return RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(v);
  }
}
