import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tuya_home_sdk_flutter/tuya_home_sdk_flutter.dart';

import 'tuya_service.dart';

/// Remote lock/unlock for Tuya Smart Lock SDK–compatible devices.
///
/// Uses the same [TuyaService] (Smart Life App SDK). Lock commands are sent via
/// device DPS (data points). Product-specific DP IDs may vary; see
/// [Tuya Smart Lock](https://developer.tuya.com/en/docs/iot/lock?id=K9wjnt8v958nh)
/// and your lock's DP documentation.
///
/// Reference: [Smart Lock SDK](https://developer.tuya.com/en/docs/app-development/smart-lock-sdk?id=Kdjvl28puletn)
class TuyaSmartLockService extends GetxService {
  TuyaSmartLockService({required this.tuyaService});

  final TuyaService tuyaService;

  /// Default DPS key for lock state used by many Tuya WiFi locks.
  /// Override per product if needed (see Tuya product DP documentation).
  static const String defaultLockStateDpId = '1';

  /// Value for locked state (common: "lock" or true).
  static const String dpsValueLock = 'lock';

  /// Value for unlocked state (common: "unlock" or false).
  static const String dpsValueUnlock = 'unlock';

  /// Lock the device remotely.
  /// Returns true if the command was sent successfully.
  Future<bool> lock(String deviceId) async {
    return _setLockState(deviceId, true);
  }

  /// Unlock the device remotely.
  /// Returns true if the command was sent successfully.
  Future<bool> unlock(String deviceId) async {
    return _setLockState(deviceId, false);
  }

  Future<bool> _setLockState(String deviceId, bool locked) async {
    if (!tuyaService.isInitialized) {
      if (kDebugMode) debugPrint('TuyaSmartLockService: Tuya not initialized');
      return false;
    }
    final dps = <String, dynamic>{
      defaultLockStateDpId: locked ? dpsValueLock : dpsValueUnlock,
    };
    final result = await tuyaService.publishDps(deviceId: deviceId, dps: dps);
    final ok = result != null;
    if (kDebugMode) {
      debugPrint('TuyaSmartLockService: ${locked ? "lock" : "unlock"} $deviceId => $ok');
    }
    return ok;
  }

  /// Subscribe to lock state updates (e.g. to refresh UI when lock is used locally).
  Stream<Map<String, dynamic>> onLockStateUpdated(String deviceId) {
    return tuyaService.onDeviceDpsUpdated(deviceId: deviceId).cast<Map<String, dynamic>>();
  }

  /// Returns whether the last known state (from dps map) is locked.
  /// DPS values can be "lock"/"unlock", true/false, or "1"/"2" depending on product.
  static bool isLockedFromDps(Map<String, dynamic>? dps) {
    if (dps == null || dps.isEmpty) return true;
    final v = dps[defaultLockStateDpId];
    if (v == null) return true;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'lock' || s == '1' || s == 'true';
  }

  /// Get all devices from all homes; caller can filter by name or product type for locks.
  Future<List<ThingSmartDeviceModel>> getAllDevices() async {
    if (!tuyaService.isInitialized) return [];
    final homes = await tuyaService.getHomeList();
    final List<ThingSmartDeviceModel> list = [];
    for (final home in homes) {
      final devices = await tuyaService.getHomeDevices(home.homeId.toInt());
      list.addAll(devices);
    }
    return list;
  }

  /// Get lock devices (devices whose name or productId suggests a lock).
  /// Tuya lock products often have "lock" in the product name or category.
  Future<List<ThingSmartDeviceModel>> getLockDevices() async {
    final all = await getAllDevices();
    return all.where((d) {
      final name = (d.name ?? '').toLowerCase();
      final productId = (d.productId ?? '').toLowerCase();
      return name.contains('lock') ||
          productId.contains('lock') ||
          productId.contains('door_lock');
    }).toList();
  }
}
