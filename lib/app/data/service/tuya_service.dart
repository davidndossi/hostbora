import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tuya_home_sdk_flutter/tuya_home_sdk_flutter.dart';

import '../../core/config/tuya_config.dart';

/// Service for Tuya IoT device integration.
///
/// Compatible with Tuya-based smart locks, cameras (IPC), and other devices.
/// See [Tuya Smart Camera SDK](https://developer.tuya.com/en/docs/app-development/smart-ipc-sdk?id=Kdjvlq8i9jhi2)
/// and [Tuya Home SDK Flutter](https://pub.dev/packages/tuya_home_sdk_flutter).
class TuyaService extends GetxService {
  TuyaService({required this.config});

  final TuyaConfig config;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the Tuya SDK. Call once at app startup when [TuyaConfig.isEnabled].
  Future<bool> init() async {
    if (!config.isEnabled) {
      if (kDebugMode) {
        debugPrint('TuyaService: disabled (missing app key/secret/security key)');
      }
      return false;
    }
    if (_initialized) return true;
    try {
      await TuyaHomeSdkFlutter.instance.initSdk(
        config.appKey,
        config.appSecret,
        config.securityKey,
        isDebug: config.isDebug,
      );
      _initialized = true;
      if (kDebugMode) debugPrint('TuyaService: SDK initialized');
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TuyaService: init failed $e');
        debugPrint(st.toString());
      }
      return false;
    }
  }

  /// Get list of homes for the current user (after Tuya login).
  Future<List<ThingSmartHomeModel>> getHomeList() async {
    if (!_initialized) return [];
    try {
      final list = await TuyaHomeSdkFlutter.instance.getHomeList();
      return list ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('TuyaService: getHomeList $e');
      return [];
    }
  }

  /// Get all devices in a home. Use for smart locks, cameras, etc.
  Future<List<ThingSmartDeviceModel>> getHomeDevices(int homeId) async {
    if (!_initialized) return [];
    try {
      final list = await TuyaHomeSdkFlutter.instance.getHomeDevices(homeId: homeId);
      return list ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('TuyaService: getHomeDevices $e');
      return [];
    }
  }

  /// Discover nearby Tuya devices (e.g. for pairing).
  Stream<ThingSmartDeviceModel> discoverDevices() {
    if (!_initialized) return const Stream.empty();
    return TuyaHomeSdkFlutter.instance.discoverDevices();
  }

  /// Send a command to a device (DPS = data points). Example: lock/unlock, power on/off.
  /// DPS keys are device-specific (e.g. "1" for power, "2" for lock state).
  Future<bool?> publishDps({
    required String deviceId,
    required Map<String, dynamic> dps,
  }) async {
    if (!_initialized) return null;
    try {
      return await TuyaHomeSdkFlutter.instance.publishDps(
        deviceId: deviceId,
        dps: dps,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('TuyaService: publishDps $e');
      return null;
    }
  }

  /// Subscribe to real-time device status updates (e.g. lock state, camera motion).
  Stream<TuyaDeviceEvent> onDeviceEvents({required String deviceId}) {
    if (!_initialized) return const Stream.empty();
    return TuyaHomeSdkFlutter.instance.onDeviceEvents(deviceId: deviceId);
  }

  @Deprecated('Use onDeviceEvents')
  Stream<TuyaDeviceEvent> onDeviceDpsUpdated({required String deviceId}) =>
      onDeviceEvents(deviceId: deviceId);

  /// Login with Tuya (required before getHomeList / getHomeDevices).
  /// Use after your app user is authenticated; link your user to Tuya via email/phone or OAuth.
  Future<bool> loginWithUserName({
    required String username,
    required String countryCode,
    required String password,
  }) async {
    if (!_initialized) return false;
    try {
      return await TuyaHomeSdkFlutter.instance.loginWithUserName(
        username: username,
        countryCode: countryCode,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('TuyaService: loginWithUserName $e');
      return false;
    }
  }

  /// Logout from Tuya.
  Future<bool> logout() async {
    if (!_initialized) return false;
    try {
      return await TuyaHomeSdkFlutter.instance.logout();
    } catch (e) {
      if (kDebugMode) debugPrint('TuyaService: logout $e');
      return false;
    }
  }
}
