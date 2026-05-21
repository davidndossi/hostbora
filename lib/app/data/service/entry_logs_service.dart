import 'dart:async';

import 'package:get/get.dart';
import 'package:tuya_home_sdk_flutter/tuya_home_sdk_flutter.dart';

import '../../core/utils/util.dart';
import '../../modules/entry_logs/model/entry_log_item.dart';
import '../local/entry_logs_store.dart';
import 'entry_log_mapper.dart';
import 'tuya_service.dart';
import 'tuya_smart_lock_service.dart';

class EntryLogsLoadResult {
  const EntryLogsLoadResult({
    required this.items,
    this.deviceName,
    this.locationName,
    this.lastSyncedLabel,
    this.fromCacheOnly = false,
    this.errorMessage,
  });

  final List<EntryLogItem> items;
  final String? deviceName;
  final String? locationName;
  final String? lastSyncedLabel;
  final bool fromCacheOnly;
  final String? errorMessage;
}

/// Offline-first entry logs: local GetStorage + live Tuya DPS when online.
class EntryLogsService extends GetxService {
  EntryLogsService({
    EntryLogsStore? store,
    TuyaSmartLockService? lockService,
    TuyaService? tuyaService,
  })  : _store = store ?? EntryLogsStore(),
        _lockService = lockService,
        _tuyaService = tuyaService;

  final EntryLogsStore _store;
  final TuyaSmartLockService? _lockService;
  final TuyaService? _tuyaService;

  String? _activeDeviceId;
  StreamSubscription<TuyaDeviceEvent>? _deviceEventsSub;
  String? _lastDpsSignature;

  List<EntryLogItem> loadLocalItems() {
    return _store.loadAll().map(EntryLogMapper.toItem).toList();
  }

  EntryLogsMeta? get meta => _store.loadMeta();

  /// Loads local cache first; refreshes device metadata and live stream when online.
  Future<EntryLogsLoadResult> load({bool refresh = false}) async {
    final local = loadLocalItems();
    final meta = _store.loadMeta();
    var deviceName = meta?.deviceName ?? 'Smart Lock';
    var locationName = meta?.locationName ?? '';
    var lastSyncedLabel = _formatSyncedLabel(meta?.lastSyncedMs);
    String? errorMessage;

    final connectivity = await Util().checkConnectivity();
    final isOnline = connectivity != 'None' && connectivity.isNotEmpty;

    if (!isOnline) {
      return EntryLogsLoadResult(
        items: local,
        deviceName: deviceName,
        locationName: locationName,
        lastSyncedLabel: lastSyncedLabel,
        fromCacheOnly: true,
      );
    }

    if (!Get.isRegistered<TuyaSmartLockService>() ||
        !Get.isRegistered<TuyaService>()) {
      return EntryLogsLoadResult(
        items: local,
        deviceName: deviceName,
        locationName: locationName,
        lastSyncedLabel: lastSyncedLabel,
        fromCacheOnly: true,
        errorMessage: local.isEmpty ? 'Tuya is not configured' : null,
      );
    }

    final lockService = _lockService ?? Get.find<TuyaSmartLockService>();
    final tuyaService = _tuyaService ?? Get.find<TuyaService>();

    if (!tuyaService.isInitialized) {
      return EntryLogsLoadResult(
        items: local,
        deviceName: deviceName,
        locationName: locationName,
        lastSyncedLabel: lastSyncedLabel,
        fromCacheOnly: true,
        errorMessage: local.isEmpty ? 'Tuya SDK not initialized' : null,
      );
    }

    try {
      final locks = await lockService.getLockDevices();
      if (locks.isEmpty) {
        return EntryLogsLoadResult(
          items: local,
          deviceName: deviceName,
          locationName: locationName,
          lastSyncedLabel: lastSyncedLabel,
          fromCacheOnly: true,
          errorMessage: local.isEmpty ? 'No lock devices found' : null,
        );
      }

      final device = locks.first;
      final deviceId = device.devId ?? device.uuid;
      deviceName = device.name;
      locationName = device.isOnline ? 'Online' : 'Offline';

      await _store.saveMeta(
        EntryLogsMeta(
          deviceId: deviceId,
          deviceName: deviceName,
          locationName: locationName,
          lastSyncedMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      lastSyncedLabel = _formatSyncedLabel(DateTime.now().millisecondsSinceEpoch);

      if (refresh || local.isEmpty) {
        final snapshot = EntryLogMapper.fromDeviceSnapshot(device);
        if (snapshot != null) {
          await _persistIfNew(snapshot);
        }
      }

      await _startDeviceListener(deviceId, deviceName, tuyaService);

      final items = loadLocalItems();
      return EntryLogsLoadResult(
        items: items,
        deviceName: deviceName,
        locationName: locationName,
        lastSyncedLabel: lastSyncedLabel,
        fromCacheOnly: false,
      );
    } catch (e) {
      errorMessage = '$e';
      return EntryLogsLoadResult(
        items: local,
        deviceName: deviceName,
        locationName: locationName,
        lastSyncedLabel: lastSyncedLabel,
        fromCacheOnly: true,
        errorMessage: errorMessage,
      );
    }
  }

  Future<void> recordAppUnlock({
    String? deviceId,
    String? deviceName,
    String actorLabel = 'Host',
  }) async {
    final id = deviceId ?? _activeDeviceId ?? meta?.deviceId ?? 'local';
    final name = deviceName ?? meta?.deviceName ?? 'Smart Lock';
    await _persistIfNew(
      EntryLogMapper.appUnlock(
        deviceId: id,
        deviceName: name,
        actorLabel: actorLabel,
      ),
    );
  }

  Future<void> recordAppLock({
    String? deviceId,
    String? deviceName,
    String actorLabel = 'Host',
  }) async {
    final id = deviceId ?? _activeDeviceId ?? meta?.deviceId ?? 'local';
    final name = deviceName ?? meta?.deviceName ?? 'Smart Lock';
    await _persistIfNew(
      EntryLogMapper.appLock(
        deviceId: id,
        deviceName: name,
        actorLabel: actorLabel,
      ),
    );
  }

  Future<void> _startDeviceListener(
    String deviceId,
    String deviceName,
    TuyaService tuyaService,
  ) async {
    if (_activeDeviceId == deviceId && _deviceEventsSub != null) return;
    await _deviceEventsSub?.cancel();
    _activeDeviceId = deviceId;
    _lastDpsSignature = null;

    _deviceEventsSub = tuyaService
        .onDeviceEvents(deviceId: deviceId)
        .where((e) => e is DpsUpdateEvent)
        .cast<DpsUpdateEvent>()
        .listen((event) async {
      final signature =
          '${event.deviceId}:${event.dps[TuyaSmartLockService.defaultLockStateDpId]}';
      if (_lastDpsSignature == signature) return;
      _lastDpsSignature = signature;

      final stored = EntryLogMapper.fromDpsUpdate(
        deviceId: event.deviceId,
        deviceName: deviceName,
        dps: Map<String, dynamic>.from(event.dps),
      );
      if (stored != null) {
        await _persistIfNew(stored);
        await _store.saveMeta(
          EntryLogsMeta(
            deviceId: deviceId,
            deviceName: deviceName,
            locationName: meta?.locationName,
            lastSyncedMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    });
  }

  Future<void> _persistIfNew(StoredEntryLog log) async {
    final all = _store.loadAll();
    final duplicate = all.any((e) {
      if (e.id == log.id) return true;
      if (e.deviceId != log.deviceId) return false;
      if (e.title != log.title) return false;
      return (log.occurredAtMs - e.occurredAtMs).abs() < 5000;
    });
    if (duplicate) return;
    await _store.upsert(log);
  }

  static String _formatSyncedLabel(int? ms) {
    if (ms == null) return '—';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void onClose() {
    _deviceEventsSub?.cancel();
    super.onClose();
  }
}
