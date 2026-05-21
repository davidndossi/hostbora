import 'package:tuya_home_sdk_flutter/tuya_home_sdk_flutter.dart';

import '../../modules/entry_logs/model/entry_log_item.dart';
import '../local/entry_logs_store.dart';
import 'tuya_smart_lock_service.dart';

/// Maps persisted / live lock events to UI models.
class EntryLogMapper {
  static EntryLogItem toItem(StoredEntryLog log) {
    return EntryLogItem(
      id: log.id,
      iconType: _iconFromKey(log.iconType),
      title: log.title,
      detail: log.detail,
      time: _formatTime(DateTime.fromMillisecondsSinceEpoch(log.occurredAtMs)),
      status: _statusFromKey(log.status),
      date: DateTime.fromMillisecondsSinceEpoch(log.occurredAtMs),
      isAppUnlock: log.isAppUnlock,
      isPinCode: log.isPinCode,
    );
  }

  static StoredEntryLog? fromDpsUpdate({
    required String deviceId,
    required String deviceName,
    required Map<String, dynamic> dps,
    DateTime? at,
  }) {
    final lockVal = dps[TuyaSmartLockService.defaultLockStateDpId];
    if (lockVal == null) return null;

    final now = at ?? DateTime.now();
    final isLocked = TuyaSmartLockService.isLockedFromDps(dps);
    final id = '${deviceId}_dps_${now.millisecondsSinceEpoch}';

    if (isLocked) {
      return StoredEntryLog(
        id: id,
        deviceId: deviceId,
        title: 'Auto-locked',
        detail: '$deviceName • System',
        iconType: 'lock',
        status: 'completed',
        occurredAtMs: now.millisecondsSinceEpoch,
        source: 'tuya_dps',
      );
    }

    return StoredEntryLog(
      id: id,
      deviceId: deviceId,
      title: 'Door unlocked',
      detail: '$deviceName • Remote / Keypad',
      iconType: 'keypad',
      status: 'success',
      occurredAtMs: now.millisecondsSinceEpoch,
      source: 'tuya_dps',
    );
  }

  static StoredEntryLog appUnlock({
    required String deviceId,
    required String deviceName,
    String actorLabel = 'Host',
  }) {
    final now = DateTime.now();
    return StoredEntryLog(
      id: '${deviceId}_app_${now.millisecondsSinceEpoch}',
      deviceId: deviceId,
      title: 'Unlocked by $actorLabel',
      detail: 'Mobile App • Host Access',
      iconType: 'phone',
      status: 'success',
      occurredAtMs: now.millisecondsSinceEpoch,
      isAppUnlock: true,
      source: 'app_action',
    );
  }

  static StoredEntryLog appLock({
    required String deviceId,
    required String deviceName,
    String actorLabel = 'Host',
  }) {
    final now = DateTime.now();
    return StoredEntryLog(
      id: '${deviceId}_app_lock_${now.millisecondsSinceEpoch}',
      deviceId: deviceId,
      title: 'Locked by $actorLabel',
      detail: 'Mobile App • Remote Lock',
      iconType: 'lock',
      status: 'completed',
      occurredAtMs: now.millisecondsSinceEpoch,
      source: 'app_action',
    );
  }

  /// Seeds an initial state log from device snapshot when no history exists.
  static StoredEntryLog? fromDeviceSnapshot(ThingSmartDeviceModel device) {
    final dps = device.dps;
    if (dps == null || dps.isEmpty) return null;
    final map = Map<String, dynamic>.from(
      dps.map((k, v) => MapEntry(k.toString(), v)),
    );
    return fromDpsUpdate(
      deviceId: device.devId ?? device.uuid,
      deviceName: device.name,
      dps: map,
      at: DateTime.now(),
    );
  }

  static EntryLogIconType _iconFromKey(String key) => switch (key) {
        'phone' => EntryLogIconType.phone,
        'key' => EntryLogIconType.key,
        'keypad' => EntryLogIconType.keypad,
        'warning' => EntryLogIconType.warning,
        _ => EntryLogIconType.lock,
      };

  static EntryLogStatus _statusFromKey(String key) => switch (key) {
        'success' => EntryLogStatus.success,
        'manual' => EntryLogStatus.manual,
        'alert' => EntryLogStatus.alert,
        _ => EntryLogStatus.completed,
      };

  static String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}
