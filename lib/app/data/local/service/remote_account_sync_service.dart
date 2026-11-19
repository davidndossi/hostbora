import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/access/staff_access.dart';
import '../../../core/utils/property_remote_rent.dart';
import '../../../core/utils/sync_freshness.dart';
import '../../../modules/add_listing/models/apartment_unit_draft.dart';
import '../../../network/exceptions/not_found_exception.dart';
import '../../model/general_response.dart';
import '../../repository/app_repository.dart';
import '../../../modules/rent/staff_management/utils/rent_staff_pay_format.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_listing_units_sync.dart';
import '../db/property_local_data_source.dart';
import '../db/property_members_local_data_source.dart';
import '../db/property_unit_local_data_source.dart';
import '../db/rent_staff_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../deleted_properties_store.dart';
import '../preference/preference_manager.dart';
import 'account_recency_sync.dart';
import 'local_account_data_reset.dart';
import 'offline_sync_worker_service.dart';
import 'property_remote_create.dart';

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
      await LocalAccountDataReset.alignToUser(_preferenceManager);
      await _syncWorker.runNow(maxItems: 50);
      await syncAccess();
      await syncProperties();
      await Future.wait([
        syncTenants(),
        syncStaffFromRemote(),
      ]);
      await AccountRecencySync(
        repository: _repository,
        syncQueue: _syncQueue,
      ).run();
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
      if (Get.isRegistered<StaffAccessStore>()) {
        await Get.find<StaffAccessStore>().applyPayload(map);
      }

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
      final remoteMaps = await _collectRemotePropertyMaps();

      final remoteRefs = <String>{};
      final remoteNameLoc = <String>{};
      for (final map in remoteMaps) {
        final ref = _refFromApiMap(map);
        if (ref.isNotEmpty) remoteRefs.add(ref);
        final key = _nameLocKey(
          PropertyRecord.remoteName(map),
          PropertyRecord.remoteLocation(map),
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
          final name = PropertyRecord.remoteName(map);
          final ws = PropertyRecord.workspaceFromApiMap(map) ?? '';
          debugPrint('[PropertySync]  remote ref="$ref" name="$name" workspace="$ws"');
        }
      }

      // Remote → local for every property the server returned.
      final deleted = DeletedPropertiesStore().load();
      for (final map in remoteMaps) {
        final ref = _refFromApiMap(map);
        if (ref.isNotEmpty && deleted.contains(ref)) continue;
        final record = _propertyFromApiMap(map, ownerUserId: sessionUserId);
        // Snapshot phone units before upsert. A newer server property row
        // used to replace units_json and delete phone-only units.
        final existing = ref.isNotEmpty
            ? await _propertyLocal.getByPropertyRef(ref)
            : null;
        final localUnits = await _localUnitDrafts(existing);
        final localClock = await _localUnitsClock(existing);
        final saved = await _propertyLocal.upsertFromRemote(record);
        final remoteUpdated = record.updatedAtMs;
        final remoteUnits = _draftsFromUnitsJson(record.unitsJson);
        final phoneNewer = SyncFreshness.phoneIsNewer(
          localUpdatedMs: localClock > 0 ? localClock : saved.updatedAtMs,
          localCreatedMs: existing?.createdAtMs ?? saved.createdAtMs,
          remoteUpdatedMs: remoteUpdated,
        );
        final merged = _mergeUnitDrafts(
          local: localUnits,
          remote: remoteUnits,
          preferLocal: phoneNewer,
        );
        final phoneOnlyUnits = _phoneHasUnitsMissingOnServer(localUnits, remoteUnits);
        var pushRow = saved;
        var pushRemote = false;
        if (phoneNewer || phoneOnlyUnits) {
          pushRow = merged.isEmpty
              ? saved
              : saved.copyWith(
                  unitsJson: jsonEncode(merged.map((d) => d.toJson()).toList()),
                  units: merged.length,
                );
          if (pushRow.unitsJson != saved.unitsJson || pushRow.units != saved.units) {
            await _propertyLocal.update(
              pushRow,
              updatedAtMs: phoneNewer
                  ? (localClock > 0 ? localClock : saved.updatedAtMs)
                  : (remoteUpdated > 0 ? remoteUpdated : saved.updatedAtMs),
            );
          }
          pushRemote = true;
          if (merged.isNotEmpty) {
            await _writeUnitRows(pushRow, merged);
          }
        } else {
          await _applyRemoteUnits(saved, remoteUpdated);
        }
        final liveTenants = await _tenantLocal.countByPropertyRef(pushRow.propertyRef);
        if (liveTenants != pushRow.tenants || liveTenants != record.tenants) {
          pushRow = pushRow.copyWith(tenants: liveTenants);
          await _propertyLocal.update(pushRow);
          pushRemote = true;
        }
        if (pushRemote) {
          await _pushLocalPropertyUpdate(pushRow);
        }
        if (sessionUserId.isNotEmpty &&
            record.propertyRef.trim().isNotEmpty &&
            record.ownerUserId.trim() != sessionUserId) {
          await _propertyMembers.upsertMember(
            propertyRef: record.propertyRef.trim(),
            userId: sessionUserId,
            workspaceType: record.workspaceType.trim().isEmpty
                ? 'rent'
                : record.workspaceType.trim(),
            role: isManager ? 'manager' : 'owner',
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
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PropertySync] syncProperties failed: $e\n$st');
      }
    }
  }

  /// Pulls host inventory from `/api/properties`.
  Future<List<Map<String, dynamic>>> _collectRemotePropertyMaps() async {
    final byKey = <String, Map<String, dynamic>>{};

    void addAll(List<Map<String, dynamic>> maps) {
      for (final map in maps) {
        final ref = _refFromApiMap(map);
        final name = PropertyRecord.remoteName(map).toLowerCase();
        final loc = PropertyRecord.remoteLocation(map).toLowerCase();
        final key = ref.isNotEmpty
            ? 'ref:$ref'
            : (name.isEmpty && loc.isEmpty
                ? 'anon:${byKey.length}'
                : 'nl:$name|$loc');
        byKey.putIfAbsent(key, () => map);
      }
    }

    Future<void> pull(
      String label,
      Future<GeneralResponse> Function() call,
    ) async {
      try {
        final res = await call();
        if (res.data == null) return;
        addAll(_extractMaps(res.data));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PropertySync] $label failed: $e');
        }
      }
    }

    await pull('GET /api/properties', _repository.getMyProperties);
    return byKey.values.toList();
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
    // Staff list is owner-only on the API — skip for restricted staff sessions
    // so we don't spam 403s after login.
    if (Get.isRegistered<StaffAccessStore>() &&
        Get.find<StaffAccessStore>().restricted.value) {
      return;
    }
    try {
      final res = await _repository.getStaffList();
      if (!res.isSuccess || res.data == null) return;
      for (final map in _extractMaps(res.data)) {
        await _staffLocal.upsertFromRemote(_staffFromApiMap(map));
      }
    } catch (_) {}
  }

  Future<String> _tenantPropertyName(TenantRecord row) async {
    final label = row.propertyLabel.trim();
    final ref = row.propertyRef.trim();
    final labelIsRef = label.isEmpty ||
        label == ref ||
        label.startsWith('local_') ||
        label.startsWith('legacy_');
    if (!labelIsRef) return label;
    if (ref.isEmpty) return '';
    final property = await _propertyLocal.findByHubId(ref);
    if (property == null) return '';
    final name = property.propertyName.trim();
    if (name.isNotEmpty) return name;
    return property.propertyLocation.trim();
  }

  Future<void> _pushLocalTenantToRemote(TenantRecord row) async {
    final name = row.tenantName.trim();
    if (name.isEmpty) return;
    final propertyName = await _tenantPropertyName(row);
    final payload = {
      'name': name,
      'phone': row.phoneNumber.trim(),
      'email': row.email.trim(),
      'propertyRef': row.propertyRef.trim(),
      'property_name': propertyName,
      'propertyName': propertyName,
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

  Future<bool> _sessionOwnsPropertyRef(String propertyRef) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return false;
    String userId = '';
    try {
      userId = ((await _preferenceManager.getUser()).id ?? '').trim();
    } catch (_) {
      return false;
    }
    if (userId.isEmpty) return false;
    final rows = await _propertyLocal.fetchAll(userId: userId);
    for (final row in rows) {
      if (row.propertyRef.trim() == ref) return true;
      if (ref == 'local_${row.id}' || ref == 'legacy_${row.id}') return true;
    }
    return false;
  }

  Future<void> _upsertTenantFromApiMap(Map<String, dynamic> map) async {
    final backendId = (map['id'] ?? '').toString().trim();
    final name = (map['name'] ?? '').toString().trim();
    if (name.isEmpty && backendId.isEmpty) return;
    final propertyRef =
        (map['propertyRef'] ?? map['property_ref'] ?? '').toString().trim();
    final propertyName =
        (map['propertyName'] ?? map['property_name'] ?? '').toString().trim();
    if (!await _sessionOwnsPropertyRef(propertyRef)) return;
    final saved = await _tenantLocal.upsertFromRemote(
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
      remoteUpdatedAtMs: SyncFreshness.fromMap(map),
      tenancyStatus: (map['tenancyStatus'] ??
              map['tenancy_status'] ??
              map['status'] ??
              '')
          .toString(),
    );
    if (SyncFreshness.phoneIsNewer(
      localUpdatedMs: saved.updatedAtMs,
      localCreatedMs: saved.createdAtMs,
      remoteUpdatedMs: SyncFreshness.fromMap(map),
    )) {
      await _pushLocalTenantUpdate(saved);
    }
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

  /// Writes the live active-tenant count onto the property and pushes it to
  /// the remote `properties.tenants` column.
  Future<void> publishTenantCount(String propertyRef) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return;
    final property = await _propertyLocal.getByPropertyRef(ref) ??
        await _propertyLocal.findByHubId(ref);
    if (property == null) return;
    final countRef = property.propertyRef.trim().isNotEmpty
        ? property.propertyRef.trim()
        : ref;
    final count = await _tenantLocal.countByPropertyRef(countRef);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = property.copyWith(tenants: count, updatedAtMs: now);
    if (property.tenants != count) {
      await _propertyLocal.update(updated, updatedAtMs: now);
    }
    await _pushLocalPropertyUpdate(updated);
  }

  static void publishTenantCountFor(String propertyRef) {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return;
    if (!Get.isRegistered<RemoteAccountSyncService>()) return;
    unawaited(
      Get.find<RemoteAccountSyncService>().publishTenantCount(ref),
    );
  }

  Future<void> _pushLocalPropertyToRemote(PropertyRecord row) async {
    final payload = await _payloadFor(row);
    final ref = (payload['property_ref'] as String?)?.trim() ?? '';
    if (ref.isEmpty) return;
    final name = (payload['name'] as String?)?.trim() ?? '';
    final location = (payload['location'] as String?)?.trim() ?? '';
    if (name.isEmpty && location.isEmpty) return;

    final ok = await PropertyRemoteCreate.once(
      repository: _repository,
      payload: payload,
    );
    if (ok) return;
    try {
      await _syncQueue.enqueue(
        entityType: 'property',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'property:create:$ref',
      );
    } catch (_) {}
  }

  /// Updates the remote row by the ref already stored on the phone.
  ///
  /// `local_…` refs are sent as `property_ref` on create, so a later change
  /// must PUT that ref. Posting again inserts a second property.
  Future<void> _pushLocalPropertyUpdate(PropertyRecord row) async {
    final ref = row.propertyRef.trim();
    if (ref.isEmpty) return;
    final payload = await _payloadFor(row);
    payload['updated_at_ms'] = row.updatedAtMs > 0
        ? row.updatedAtMs
        : DateTime.now().millisecondsSinceEpoch;

    Future<bool> put() async {
      try {
        final res = await _repository.updatePropertyByRef(ref, payload);
        if (PropertyRemoteCreate.responseAccepted(res)) return true;
      } on NotFoundException {
        return false;
      } catch (_) {
        await _enqueuePropertyUpdate(ref, payload);
        return true;
      }
      await _enqueuePropertyUpdate(ref, payload);
      return true;
    }

    if (await put()) return;

    final pending = PropertyRemoteCreate.wait(ref);
    if (pending != null) {
      await pending;
      if (await put()) return;
    }
    if (PropertyRemoteCreate.wasAccepted(ref)) {
      await _enqueuePropertyUpdate(ref, payload);
      return;
    }
    await _pushLocalPropertyToRemote(row);
  }

  Future<void> _enqueuePropertyUpdate(
    String ref,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'property',
        operation: 'update',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'property:update:$ref',
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _payloadFor(PropertyRecord row) async {
    final payload = _createPayloadFromLocal(row);
    final ref = row.propertyRef.trim();
    if (ref.isNotEmpty) {
      payload['tenants'] = await _tenantLocal.countByPropertyRef(ref);
    }
    return payload;
  }

  Future<void> _pushLocalTenantUpdate(TenantRecord row) async {
    final backendId = row.backendTenantId.trim();
    final payload = {
      'id': backendId,
      'name': row.tenantName.trim(),
      'phone': row.phoneNumber.trim(),
      'email': row.email.trim(),
      'propertyRef': row.propertyRef.trim(),
      'unitId': row.apartmentUnitId.trim(),
      'unitName': row.unitLabel.trim(),
      'leaseStart': row.leaseStartIso.trim(),
      'leaseEnd': row.leaseEndIso.trim(),
      'rentAmount': row.rentAmountValue,
      'rentFrequency': row.rentFrequency.trim(),
      'rentCurrency': row.rentCurrency.trim(),
      'tenancyStatus': row.tenancyStatus.trim(),
      'localTenantId': row.id,
      'updated_at_ms':
          row.updatedAtMs > 0 ? row.updatedAtMs : row.createdAtMs,
    };
    if (backendId.isEmpty) return;
    try {
      final body = Map<String, dynamic>.from(payload)..remove('localTenantId');
      final res = await _repository.updateTenant(backendId, body);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'updateTenant failed');
    } catch (_) {
      try {
        await _syncQueue.enqueue(
          entityType: 'tenant',
          operation: 'update',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'tenant:update:${row.id}',
        );
      } catch (_) {}
    }
  }

  /// Units saved on the phone, from `units_json` and the `property_units` table.
  ///
  /// Table rows are included for every ref alias. Adding units used to update
  /// the phone only, so the server property could stay at one unit.
  Future<List<ApartmentUnitDraft>> _localUnitDrafts(PropertyRecord? row) async {
    if (row == null) return const [];
    final drafts = _draftsFromUnitsJson(row.unitsJson);
    if (!Get.isRegistered<PropertyUnitLocalDataSource>()) return drafts;
    final units = Get.find<PropertyUnitLocalDataSource>();
    final refs = <String>{
      row.propertyRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    };
    for (final ref in refs) {
      if (ref.isEmpty) continue;
      final rows = await units.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final unit in rows) {
        final name = unit.unitName.trim();
        if (name.isEmpty) continue;
        final draft = ApartmentUnitDraft(
          unitId: unit.propertyUnitRef,
          unitName: name,
          unitRent: unit.rentAmount > 0 ? unit.rentAmount.toString() : '',
          unitRentFrequency: unit.rentFrequency,
          unitFloor: unit.floor,
          operationMode: unit.operationMode,
          unitDescription: unit.notes,
          unitRentCurrency: unit.rentCurrency,
        );
        if (drafts.any((existing) => _sameUnit(existing, draft))) continue;
        drafts.add(draft);
      }
    }
    return drafts;
  }

  Future<int> _localUnitsClock(PropertyRecord? row) async {
    if (row == null) return 0;
    var clock = row.updatedAtMs > 0 ? row.updatedAtMs : row.createdAtMs;
    if (!Get.isRegistered<PropertyUnitLocalDataSource>()) return clock;
    final units = Get.find<PropertyUnitLocalDataSource>();
    final refs = <String>{
      row.propertyRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    };
    for (final ref in refs) {
      if (ref.isEmpty) continue;
      final stamp = await units.maxUpdatedAtForProperty(ref);
      if (stamp > clock) clock = stamp;
    }
    return clock;
  }

  List<ApartmentUnitDraft> _mergeUnitDrafts({
    required List<ApartmentUnitDraft> local,
    required List<ApartmentUnitDraft> remote,
    required bool preferLocal,
  }) {
    final primary = preferLocal ? local : remote;
    final secondary = preferLocal ? remote : local;
    final merged = <ApartmentUnitDraft>[...primary];
    for (final draft in secondary) {
      if (draft.unitName.trim().isEmpty) continue;
      if (merged.any((existing) => _sameUnit(existing, draft))) continue;
      merged.add(draft);
    }
    return merged;
  }

  bool _phoneHasUnitsMissingOnServer(
    List<ApartmentUnitDraft> local,
    List<ApartmentUnitDraft> remote,
  ) {
    for (final draft in local) {
      if (draft.unitName.trim().isEmpty) continue;
      if (!remote.any((existing) => _sameUnit(existing, draft))) return true;
    }
    return false;
  }

  bool _sameUnit(ApartmentUnitDraft a, ApartmentUnitDraft b) {
    final aId = a.unitId.trim().toLowerCase();
    final bId = b.unitId.trim().toLowerCase();
    if (aId.isNotEmpty && bId.isNotEmpty && aId == bId) return true;
    final aName = a.unitName.trim().toLowerCase();
    final bName = b.unitName.trim().toLowerCase();
    return aName.isNotEmpty && aName == bName;
  }

  List<ApartmentUnitDraft> _draftsFromUnitsJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '[]' || text == 'null') return [];
    try {
      final value = jsonDecode(text);
      if (value is! List) return [];
      final out = <ApartmentUnitDraft>[];
      for (final item in value) {
        if (item is! Map) continue;
        final draft = ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(item));
        if (draft.unitName.trim().isEmpty) continue;
        out.add(draft);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeUnitRows(
    PropertyRecord row,
    List<ApartmentUnitDraft> drafts,
  ) async {
    if (!Get.isRegistered<PropertyUnitLocalDataSource>() || drafts.isEmpty) {
      return;
    }
    final ref = row.propertyRef.trim().isNotEmpty
        ? row.propertyRef.trim()
        : 'local_${row.id}';
    await syncPropertyUnitsForListingSave(
      unitLocal: Get.find<PropertyUnitLocalDataSource>(),
      propertyRef: ref,
      isApartment: true,
      apartmentUnitMaps: drafts.map((d) => d.toJson()).toList(),
      minRentalDuration: row.minRentalDuration,
      listingRentFrequency: row.rentFrequency,
      listingRentRaw: row.rentAmount,
      singleUnitName: row.propertyName,
      rooms: 0,
      maxGuests: 0,
      listingMode: row.workspaceType,
    );
  }

  Future<void> _applyRemoteUnits(PropertyRecord row, int remoteUpdatedMs) async {
    if (!Get.isRegistered<PropertyUnitLocalDataSource>()) return;
    final raw = row.unitsJson.trim();
    if (raw.isEmpty) return;
    List<dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! List || value.isEmpty) return;
      decoded = value;
    } catch (_) {
      return;
    }
    final maps = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final draft = ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(item));
      if (draft.unitName.trim().isEmpty) continue;
      maps.add(draft.toJson());
    }
    if (maps.isEmpty) return;
    final units = Get.find<PropertyUnitLocalDataSource>();
    await syncPropertyUnitsForListingSave(
      unitLocal: units,
      propertyRef: row.propertyRef,
      isApartment: true,
      apartmentUnitMaps: maps,
      minRentalDuration: row.minRentalDuration,
      listingRentFrequency: row.rentFrequency,
      listingRentRaw: row.rentAmount,
      singleUnitName: row.propertyName,
      rooms: 0,
      maxGuests: 0,
      listingMode: row.workspaceType,
    );
    final stamp = remoteUpdatedMs > 0
        ? remoteUpdatedMs
        : (row.updatedAtMs > 0 ? row.updatedAtMs : row.createdAtMs);
    await units.stampUpdatedAtForProperty(row.propertyRef, stamp);
  }

  static Map<String, dynamic> _createPayloadFromLocal(PropertyRecord row) {
    var ref = row.propertyRef.trim();
    if (ref.isEmpty) {
      ref = 'local_${row.id}';
    }
    final owner = row.ownerUserId.trim();
    final rentAmount = PropertyRemoteRent.amount(
      unitCount: row.units,
      listingRentAmount: row.rentAmount,
      unitsJson: row.unitsJson,
    );
    final rentFrequency = PropertyRemoteRent.frequency(
      unitCount: row.units,
      listingRentFrequency: row.rentFrequency,
      unitsJson: row.unitsJson,
      rentAmount: rentAmount,
    );
    return {
      'property_ref': ref,
      'location': row.propertyLocation,
      'name': row.propertyName,
      'type': row.propertyType,
      'tenants': row.tenants,
      'units': row.units,
      'owner_user_id': owner,
      'workspace_type': row.workspaceType,
      'created_at_ms': row.createdAtMs,
      'rent_amount': rentAmount,
      'rent_frequency': rentFrequency,
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
    return PropertyRecord.remoteRef(m);
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
        'records',
        'result',
        'list',
        'rows',
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
    final ref = PropertyRecord.remoteRef(m);
    final createdAtMs = (m['created_at_ms'] as num?)?.toInt() ??
        (m['createdAtMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final unitsJson = _unitsJsonFromApiMap(m);
    final remoteOwner = PropertyRecord.remoteOwner(m);

    return PropertyRecord(
      id: 0,
      propertyName: PropertyRecord.remoteName(m),
      propertyType: PropertyRecord.remoteType(m),
      propertyLocation: PropertyRecord.remoteLocation(m),
      propertyRef: ref.isNotEmpty ? ref : 'remote_$createdAtMs',
      tenants: (m['tenants'] as num?)?.toInt() ?? 0,
      units: _unitsCountFromApiMap(m, unitsJson),
      ownerUserId:
          ownerUserId.trim().isNotEmpty ? ownerUserId.trim() : remoteOwner,
      workspaceType: PropertyRecord.workspaceFromApiMap(m) ?? '',
      createdAtMs: createdAtMs,
      rentAmount: PropertyRecord.remoteRentAmount(m),
      rentFrequency: PropertyRecord.remoteRentFrequency(m),
      minRentalDuration: PropertyRecord.remoteMinDuration(m),
      unitsJson: unitsJson,
      floorCount: ((m['floor_count'] ?? m['floorCount']) as num?)?.toInt() ?? 1,
      coverPhotoPath: PropertyRecord.remoteCoverPhoto(m),
      listingStatus: '',
      updatedAtMs: 0,
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

  /// Keeps a JSON array when the API sends `units_json` as a list, or `units` as unit objects.
  static String _unitsJsonFromApiMap(Map<String, dynamic> m) {
    final raw = m['units_json'] ?? m['unitsJson'];
    if (raw is String) {
      final text = raw.trim();
      if (text.isNotEmpty && text != '[]' && text != 'null') return text;
    } else if (raw is List || raw is Map) {
      try {
        final encoded = jsonEncode(raw);
        if (encoded != '[]' && encoded != '{}' && encoded != 'null') {
          return encoded;
        }
      } catch (_) {}
    }
    return raw is String ? raw.trim() : '';
  }

  static int _unitsCountFromApiMap(Map<String, dynamic> m, String unitsJson) {
    final units = m['units'];
    if (units is num && units > 0) return units.toInt();
    final fromJson = _countNamedUnits(unitsJson);
    if (fromJson > 0) return fromJson;
    if (units is num) return units.toInt();
    return 0;
  }

  static int _countNamedUnits(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '[]' || text == 'null') return 0;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return 0;
      var count = 0;
      for (final item in decoded) {
        if (item is Map) {
          final name = (item['unitName'] ?? item['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
        }
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  static String _payDayFromNotes(String notes) {
    final match = RegExp(r'pay day:\s*(\d{1,2})', caseSensitive: false)
        .firstMatch(notes);
    return match?.group(1) ?? '';
  }
}
