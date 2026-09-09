import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../repository/app_repository.dart';
import '../../../modules/rent/staff_management/utils/rent_staff_pay_format.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/property_members_local_data_source.dart';
import '../db/rent_staff_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../deleted_properties_store.dart';
import '../preference/preference_manager.dart';
import 'offline_sync_worker_service.dart';

/// Reconciles account-scoped properties, tenants, and staff between the backend
/// and local SQLite so the same user stays consistent across devices.
///
/// Property/tenant sync is bidirectional:
/// - Remote present → upsert locally
/// - Local present but missing remotely → create on remote (or enqueue offline)
class RemoteAccountSyncService extends GetxService {
  RemoteAccountSyncService({
    required AppRepository repository,
    required PropertyLocalDataSource propertyLocal,
    required TenantLocalDataSource tenantLocal,
    required RentStaffLocalDataSource staffLocal,
    required PropertyMembersLocalDataSource propertyMembers,
    required PreferenceManager preferenceManager,
    required OfflineSyncWorkerService syncWorker,
    required OfflineSyncQueueLocalDataSource syncQueue,
  })  : _repository = repository,
        _propertyLocal = propertyLocal,
        _tenantLocal = tenantLocal,
        _staffLocal = staffLocal,
        _propertyMembers = propertyMembers,
        _preferenceManager = preferenceManager,
        _syncWorker = syncWorker,
        _syncQueue = syncQueue;

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final RentStaffLocalDataSource _staffLocal;
  final PropertyMembersLocalDataSource _propertyMembers;
  final PreferenceManager _preferenceManager;
  final OfflineSyncWorkerService _syncWorker;
  final OfflineSyncQueueLocalDataSource _syncQueue;

  bool _syncing = false;

  /// Drain offline queue, then reconcile properties + tenants + pull staff.
  /// Safe to call fire-and-forget after login.
  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncWorker.runNow(maxItems: 50);
      await syncAccess();
      await Future.wait([
        syncProperties(),
        syncTenants(),
        syncStaffFromRemote(),
      ]);
    } catch (_) {
      // Best-effort — local data remains usable offline.
    } finally {
      _syncing = false;
    }
  }

  /// Pull portfolio manager grants and persist acting-as host for API headers.
  Future<void> syncAccess() async {
    try {
      final res = await _repository.getMyAccess();
      if (!res.isSuccess || res.data == null) return;
      final data = res.data;
      Map<String, dynamic>? map;
      if (data is Map) {
        map = Map<String, dynamic>.from(data);
      }
      if (map == null) return;

      final managedRaw = map['managedHosts'];
      final hosts = <Map<String, dynamic>>[];
      if (managedRaw is List) {
        for (final e in managedRaw) {
          if (e is Map) hosts.add(Map<String, dynamic>.from(e));
        }
      }

      final isManager = map['isManager'] == true || hosts.isNotEmpty;
      await _preferenceManager.setBool(
        PreferenceManager.keyIsPortfolioManager,
        isManager,
      );
      if (hosts.isNotEmpty) {
        final first = hosts.first;
        final hostId = (first['hostUserId'] ?? '').toString().trim();
        final hostName = (first['hostName'] ?? first['hostPhone'] ?? '')
            .toString()
            .trim();
        await _preferenceManager.setString(
          PreferenceManager.keyActingAsHostUserId,
          hostId,
        );
        await _preferenceManager.setString(
          PreferenceManager.keyManagedHostName,
          hostName,
        );
      } else {
        await _preferenceManager.remove(
          PreferenceManager.keyActingAsHostUserId,
        );
        await _preferenceManager.remove(PreferenceManager.keyManagedHostName);
        // Revoked (or never a manager): drop local manager memberships so
        // host portfolio rows stop showing via property_members visibility.
        final sessionUserId =
            ((await _preferenceManager.getUser()).id ?? '').trim();
        if (sessionUserId.isNotEmpty) {
          await _propertyMembers.deleteAllForUserWithRole(
            userId: sessionUserId,
            role: 'manager',
          );
        }
      }
    } catch (_) {}
  }

  /// Bidirectional property sync (remote↔local). Prefer this after login.
  Future<void> syncProperties() async {
    try {
      final sessionUserId =
          ((await _preferenceManager.getUser()).id ?? '').trim();
      final isManager = await _preferenceManager.getBool(
        PreferenceManager.keyIsPortfolioManager,
        defaultValue: false,
      );
      final res = await _repository.getMyProperties();
      final remoteMaps =
          (res.isSuccess && res.data != null) ? _extractMaps(res.data) : const <Map<String, dynamic>>[];

      final remoteRefs = <String>{};
      final remoteNameLoc = <String>{};
      for (final map in remoteMaps) {
        final ref = _refFromApiMap(map);
        if (ref.isNotEmpty) remoteRefs.add(ref);
        final key = _nameLocKey(
          (map['name'] ?? map['propertyName'] ?? map['title'] ?? '')
              .toString(),
          (map['location'] ?? map['propertyLocation'] ?? '').toString(),
        );
        if (key.isNotEmpty) remoteNameLoc.add(key);
      }

      // Local → remote for rows the server does not know about.
      // Only push properties owned by this session user (not managed host rows).
      final localRows = await _propertyLocal.fetchAll(userId: sessionUserId);
      for (final row in localRows) {
        if (_isKnownRemotely(row, remoteRefs, remoteNameLoc)) continue;
        await _pushLocalPropertyToRemote(row);
      }

      if (kDebugMode) {
        debugPrint('[PropertySync] Remote DB returned ${remoteMaps.length} properties:');
        for (final map in remoteMaps) {
          final ref  = _refFromApiMap(map);
          final name = (map['name'] ?? map['propertyName'] ?? map['title'] ?? '').toString();
          final ws   = (map['workspaceType'] ?? map['workspace_type'] ?? '').toString();
          debugPrint('[PropertySync]  remote ref="$ref" name="$name" workspace="$ws"');
        }
      }

      // Remote → local for every property the server returned.
      final deleted = DeletedPropertiesStore().load();
      for (final map in remoteMaps) {
        final ref = _refFromApiMap(map);
        if (ref.isNotEmpty && deleted.contains(ref)) continue;
        final record = _propertyFromApiMap(map, ownerUserId: sessionUserId);
        await _propertyLocal.upsertFromRemote(record);
        if (isManager &&
            sessionUserId.isNotEmpty &&
            record.propertyRef.trim().isNotEmpty &&
            record.ownerUserId.trim() != sessionUserId) {
          await _propertyMembers.upsertMember(
            propertyRef: record.propertyRef.trim(),
            userId: sessionUserId,
            workspaceType: record.workspaceType.trim().isEmpty
                ? 'rent'
                : record.workspaceType.trim(),
            role: 'manager',
          );
        }
      }

      if (kDebugMode) {
        final afterSync = await _propertyLocal.fetchAll(userId: sessionUserId);
        debugPrint('[PropertySync] Local DB after sync: ${afterSync.length} rows:');
        for (final p in afterSync) {
          debugPrint(
            '[PropertySync]  local id=${p.id} ref="${p.propertyRef}" '
            'name="${p.propertyName}" workspace="${p.workspaceType}"',
          );
        }
      }
    } catch (_) {
      // Offline / API error — keep local data; next login or Main sync retries.
    }
  }

  /// Pull-only convenience used by My Properties refresh.
  Future<void> syncPropertiesFromRemote() => syncProperties();

  /// Bidirectional tenant sync (remote↔local).
  Future<void> syncTenants() async {
    try {
      final res = await _repository.getMyTenants();
      final remoteMaps = (res.isSuccess && res.data != null)
          ? _extractMaps(res.data)
          : const <Map<String, dynamic>>[];

      final remoteBackendIds = <String>{};
      final remotePhonePropKeys = <String>{};
      final remoteNamePropKeys = <String>{};
      for (final map in remoteMaps) {
        final id = (map['id'] ?? '').toString().trim();
        if (id.isNotEmpty) remoteBackendIds.add(id);
        final phone = (map['phone'] ?? '').toString().trim();
        final propRef = (map['propertyRef'] ?? map['property_ref'] ?? '')
            .toString()
            .trim();
        final name = (map['name'] ?? '').toString().trim().toLowerCase();
        final phoneKey = _tenantPhonePropKey(phone, propRef);
        if (phoneKey.isNotEmpty) remotePhonePropKeys.add(phoneKey);
        final nameKey = _tenantNamePropKey(name, propRef);
        if (nameKey.isNotEmpty) remoteNamePropKeys.add(nameKey);
      }

      final localRows = await _tenantLocal.getAllNewestFirst();
      for (final row in localRows) {
        if (_isTenantKnownRemotely(
          row,
          remoteBackendIds,
          remotePhonePropKeys,
          remoteNamePropKeys,
        )) {
          continue;
        }
        await _pushLocalTenantToRemote(row);
      }

      for (final map in remoteMaps) {
        await _upsertTenantFromApiMap(map);
      }
    } catch (_) {
      // Offline / API error — keep local tenants; next sync retries.
    }
  }

  Future<void> syncStaffFromRemote() async {
    try {
      final res = await _repository.getStaffList();
      if (!res.isSuccess || res.data == null) return;
      for (final map in _extractMaps(res.data)) {
        await _staffLocal.upsertFromRemote(_staffFromApiMap(map));
      }
    } catch (_) {}
  }

  Future<void> _pushLocalTenantToRemote(TenantRecord row) async {
    final name = row.tenantName.trim();
    if (name.isEmpty) return;
    final payload = {
      'name': name,
      'phone': row.phoneNumber.trim(),
      'email': row.email.trim(),
      'propertyRef': row.propertyRef.trim(),
      'propertyName': row.propertyLabel.trim(),
      'unitId': row.apartmentUnitId.trim(),
      'unitName': row.unitLabel.trim(),
      'leaseStart': row.leaseStartIso.trim(),
      'leaseEnd': row.leaseEndIso.trim(),
      'rentAmount': row.rentAmountValue,
      'rentFrequency': row.rentFrequency.trim(),
      'operationMode': 'rent',
      'rentCurrency': row.rentCurrency.trim(),
      'localTenantId': row.id,
    };
    final dedupe =
        'tenant:create:${row.propertyRef.trim()}:${row.tenantName.trim()}';
    try {
      final res = await _repository.createTenant(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'createTenant failed');
      final backendId = (res.data is Map)
          ? (res.data as Map)['id']?.toString() ?? ''
          : '';
      if (backendId.isNotEmpty) {
        await _tenantLocal.saveBackendTenantId(
          localId: row.id,
          backendId: backendId,
        );
      }
    } catch (_) {
      try {
        await _syncQueue.enqueue(
          entityType: 'tenant',
          operation: 'create',
          payloadJson: jsonEncode(payload),
          dedupeKey: dedupe,
        );
      } catch (_) {}
    }
  }

  Future<void> _upsertTenantFromApiMap(Map<String, dynamic> map) async {
    final backendId = (map['id'] ?? '').toString().trim();
    final name = (map['name'] ?? '').toString().trim();
    if (name.isEmpty && backendId.isEmpty) return;
    final propertyRef =
        (map['propertyRef'] ?? map['property_ref'] ?? '').toString().trim();
    final propertyName =
        (map['propertyName'] ?? map['property_name'] ?? '').toString().trim();
    await _tenantLocal.upsertFromRemote(
      backendTenantId: backendId,
      tenantName: name,
      phoneNumber: (map['phone'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      propertyRef: propertyRef,
      propertyLabel:
          propertyName.isNotEmpty ? propertyName : propertyRef,
      apartmentUnitId:
          (map['unitId'] ?? map['unit_id'] ?? '').toString().trim(),
      unitLabel: (map['unitName'] ?? map['unit_name'] ?? '').toString().trim(),
      rentAmountValue: (map['rentAmount'] as num?)?.toDouble() ??
          (map['rent_amount'] as num?)?.toDouble() ??
          0,
      rentFrequency:
          (map['rentFrequency'] ?? map['rent_frequency'] ?? '').toString(),
      leaseStartIso:
          (map['leaseStart'] ?? map['lease_start'] ?? '').toString(),
      leaseEndIso: (map['leaseEnd'] ?? map['lease_end'] ?? '').toString(),
      rentCurrency:
          (map['rentCurrency'] ?? map['rent_currency'] ?? 'TZS').toString(),
    );
  }

  static bool _isTenantKnownRemotely(
    TenantRecord row,
    Set<String> remoteBackendIds,
    Set<String> remotePhonePropKeys,
    Set<String> remoteNamePropKeys,
  ) {
    final backendId = row.backendTenantId.trim();
    if (backendId.isNotEmpty && remoteBackendIds.contains(backendId)) {
      return true;
    }
    final phoneKey =
        _tenantPhonePropKey(row.phoneNumber, row.propertyRef);
    if (phoneKey.isNotEmpty && remotePhonePropKeys.contains(phoneKey)) {
      return true;
    }
    final nameKey =
        _tenantNamePropKey(row.tenantName, row.propertyRef);
    if (nameKey.isNotEmpty && remoteNamePropKeys.contains(nameKey)) {
      return true;
    }
    return false;
  }

  static String _tenantPhonePropKey(String phone, String propertyRef) {
    final p = phone.trim();
    final r = propertyRef.trim();
    if (p.isEmpty || r.isEmpty) return '';
    return '$p|$r';
  }

  static String _tenantNamePropKey(String name, String propertyRef) {
    final n = name.trim().toLowerCase();
    final r = propertyRef.trim();
    if (n.isEmpty || r.isEmpty) return '';
    return '$n|$r';
  }

  Future<void> _pushLocalPropertyToRemote(PropertyRecord row) async {
    final payload = _createPayloadFromLocal(row);
    final ref = (payload['property_ref'] as String?)?.trim() ?? '';
    if (ref.isEmpty) return;
    final name = (payload['name'] as String?)?.trim() ?? '';
    final location = (payload['location'] as String?)?.trim() ?? '';
    if (name.isEmpty && location.isEmpty) return;

    try {
      final res = await _repository.createProperty(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'createProperty failed');
    } catch (_) {
      try {
        await _syncQueue.enqueue(
          entityType: 'property',
          operation: 'create',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'property:create:$ref',
        );
      } catch (_) {}
    }
  }

  static Map<String, dynamic> _createPayloadFromLocal(PropertyRecord row) {
    var ref = row.propertyRef.trim();
    if (ref.isEmpty) {
      ref = 'local_${row.id}';
    }
    final owner = row.ownerUserId.trim();
    return {
      'property_ref': ref,
      'location': row.propertyLocation,
      'name': row.propertyName,
      'type': row.propertyType,
      'tenants': row.tenants,
      'units': row.units,
      'owner_user_id': owner,
      'ownerUserId': owner,
      'workspace_type': row.workspaceType,
      'created_at_ms': row.createdAtMs,
      'rent_amount': row.rentAmount,
      'rent_frequency': row.rentFrequency,
      'min_rental_duration': row.minRentalDuration,
      'units_json': row.unitsJson,
      'floor_count': row.floorCount,
      'cover_photo_path': row.coverPhotoPath,
    };
  }

  static bool _isKnownRemotely(
    PropertyRecord row,
    Set<String> remoteRefs,
    Set<String> remoteNameLoc,
  ) {
    final ref = row.propertyRef.trim();
    if (ref.isNotEmpty && remoteRefs.contains(ref)) return true;
    if (remoteRefs.contains('local_${row.id}')) return true;
    if (remoteRefs.contains('legacy_${row.id}')) return true;
    final key = _nameLocKey(row.propertyName, row.propertyLocation);
    if (key.isNotEmpty && remoteNameLoc.contains(key)) return true;
    return false;
  }

  static String _nameLocKey(String name, String location) {
    final n = name.trim().toLowerCase();
    final l = location.trim().toLowerCase();
    if (n.isEmpty && l.isEmpty) return '';
    return '$n|$l';
  }

  static String _refFromApiMap(Map<String, dynamic> m) {
    return (m['property_ref'] ??
            m['propertyRef'] ??
            m['id'] ??
            m['listingId'] ??
            '')
        .toString()
        .trim();
  }

  static List<Map<String, dynamic>> _extractMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in [
        'tenants',
        'staff',
        'properties',
        'content',
        'items',
        'data',
      ]) {
        final nested = data[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  static PropertyRecord _propertyFromApiMap(
    Map<String, dynamic> m, {
    required String ownerUserId,
  }) {
    final ref = _refFromApiMap(m);
    final name =
        (m['name'] ?? m['propertyName'] ?? m['title'] ?? '').toString().trim();
    final location = (m['location'] ?? m['propertyLocation'] ?? '')
        .toString()
        .trim();
    final type =
        (m['type'] ?? m['propertyType'] ?? m['propertyCategory'] ?? '')
            .toString()
            .trim();
    final workspaceRaw = (m['workspace_type'] ??
            m['workspaceType'] ??
            m['listingMode'] ??
            m['operationMode'] ??
            'rent')
        .toString()
        .trim()
        .toLowerCase();
    final workspace = (workspaceRaw == 'bnb' ||
            workspaceRaw == 'both' ||
            workspaceRaw == 'rent')
        ? workspaceRaw
        : 'rent';
    final createdAtMs = (m['created_at_ms'] as num?)?.toInt() ??
        (m['createdAtMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    return PropertyRecord(
      id: 0,
      propertyName: name,
      propertyType: type,
      propertyLocation: location,
      propertyRef: ref.isNotEmpty ? ref : 'remote_$createdAtMs',
      tenants: (m['tenants'] as num?)?.toInt() ?? 0,
      units: (m['units'] as num?)?.toInt() ?? 0,
      ownerUserId: (m['owner_user_id'] ?? m['ownerUserId'] ?? ownerUserId)
          .toString(),
      workspaceType: workspace,
      createdAtMs: createdAtMs,
      rentAmount: (m['rent_amount'] ?? m['rentAmount'] ?? '').toString(),
      rentFrequency:
          (m['rent_frequency'] ?? m['rentFrequency'] ?? '').toString(),
      minRentalDuration: (m['min_rental_duration'] ??
              m['minRentalDuration'] ??
              '')
          .toString(),
      unitsJson: (m['units_json'] ?? m['unitsJson'] ?? '').toString(),
      floorCount: ((m['floor_count'] ?? m['floorCount']) as num?)?.toInt() ?? 1,
      coverPhotoPath: (m['cover_photo_path'] ??
              m['coverPhotoPath'] ??
              m['coverPhotoUrl'] ??
              m['imageUrl'] ??
              '')
          .toString(),
      // Empty means "not provided" so upsert keeps a local Draft/Archive.
      listingStatus: (m['listing_status'] ?? m['listingStatus'] ?? '')
          .toString()
          .trim(),
    );
  }

  static StaffRemoteUpsert _staffFromApiMap(Map<String, dynamic> m) {
    final backendId =
        (m['id'] ?? m['staffId'] ?? m['staff_id'] ?? '').toString().trim();
    final name = (m['name'] ?? '').toString().trim();
    final role =
        (m['role'] ?? m['jobTitle'] ?? m['job_title'] ?? '').toString().trim();
    final salary = (m['salary'] as num?)?.toDouble() ??
        (m['amountValue'] as num?)?.toDouble() ??
        0;
    final frequency = (m['salaryFrequency'] ??
            m['salary_frequency'] ??
            m['paymentType'] ??
            m['payment_type'] ??
            RentStaffPayFormat.monthly)
        .toString()
        .trim();
    final notes = (m['notes'] ?? '').toString();
    final payDay = _payDayFromNotes(notes);

    return StaffRemoteUpsert(
      backendId: backendId,
      name: name,
      jobTitle: role,
      payDayLabel: payDay,
      paymentType: frequency.isEmpty ? RentStaffPayFormat.monthly : frequency,
      amountValue: salary,
      phone: (m['phone'] ?? '').toString(),
      notes: notes,
      propertyRef: (m['propertyRef'] ?? m['property_ref'] ?? '').toString(),
      status: (m['status'] ?? 'active').toString(),
    );
  }

  static String _payDayFromNotes(String notes) {
    final match = RegExp(r'pay day:\s*(\d{1,2})', caseSensitive: false)
        .firstMatch(notes);
    return match?.group(1) ?? '';
  }
}
