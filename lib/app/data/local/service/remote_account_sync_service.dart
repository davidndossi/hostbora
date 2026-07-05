import 'package:get/get.dart';

import '../../repository/app_repository.dart';
import '../../../modules/rent/staff_management/utils/rent_staff_pay_format.dart';
import '../db/property_local_data_source.dart';
import '../db/rent_staff_local_data_source.dart';
import '../preference/preference_manager.dart';
import 'offline_sync_worker_service.dart';

/// Pulls account-scoped properties and staff from the backend into local SQLite
/// so the same user sees consistent data across devices.
class RemoteAccountSyncService extends GetxService {
  RemoteAccountSyncService({
    required AppRepository repository,
    required PropertyLocalDataSource propertyLocal,
    required RentStaffLocalDataSource staffLocal,
    required PreferenceManager preferenceManager,
    required OfflineSyncWorkerService syncWorker,
  })  : _repository = repository,
        _propertyLocal = propertyLocal,
        _staffLocal = staffLocal,
        _preferenceManager = preferenceManager,
        _syncWorker = syncWorker;

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final RentStaffLocalDataSource _staffLocal;
  final PreferenceManager _preferenceManager;
  final OfflineSyncWorkerService _syncWorker;

  bool _syncing = false;

  /// Push pending offline changes, then pull remote properties + staff.
  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncWorker.runNow(maxItems: 50);
      await Future.wait([
        syncPropertiesFromRemote(),
        syncStaffFromRemote(),
      ]);
    } catch (_) {
      // Best-effort — local data remains usable offline.
    } finally {
      _syncing = false;
    }
  }

  Future<void> syncPropertiesFromRemote() async {
    try {
      final res = await _repository.getMyProperties();
      if (!res.isSuccess || res.data == null) return;
      final ownerUserId = ((await _preferenceManager.getUser()).id ?? '').trim();
      for (final map in _extractMaps(res.data)) {
        await _propertyLocal.upsertFromRemote(
          _propertyFromApiMap(map, ownerUserId: ownerUserId),
        );
      }
    } catch (_) {}
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

  static List<Map<String, dynamic>> _extractMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in ['staff', 'properties', 'content', 'items', 'data']) {
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
    final ref = (m['property_ref'] ??
            m['propertyRef'] ??
            m['id'] ??
            m['listingId'] ??
            '')
        .toString()
        .trim();
    final name =
        (m['name'] ?? m['propertyName'] ?? m['title'] ?? '').toString().trim();
    final location = (m['location'] ?? m['propertyLocation'] ?? '')
        .toString()
        .trim();
    final type =
        (m['type'] ?? m['propertyType'] ?? m['propertyCategory'] ?? '')
            .toString()
            .trim();
    final workspace = (m['workspace_type'] ??
            m['workspaceType'] ??
            m['listingMode'] ??
            m['operationMode'] ??
            'rent')
        .toString()
        .trim()
        .toLowerCase();
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
      workspaceType: workspace == 'bnb' ? 'bnb' : 'rent',
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
