import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../local/preference/preference_manager.dart';
import '../repository/app_repository.dart';
import '../../routes/app_pages.dart';

/// Persists the device FCM token and registers it with the backend after login.
class FcmTokenService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> persist(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      if (Get.isRegistered<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      )) {
        await Get.find<PreferenceManager>(tag: (PreferenceManager).toString())
            .setString(PreferenceManager.keyFirebaseToken, token);
      } else {
        await _storage.write(
          key: PreferenceManager.keyFirebaseToken,
          value: token,
        );
      }
    } catch (_) {}
  }

  static Future<String> read() async {
    try {
      if (Get.isRegistered<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      )) {
        return Get.find<PreferenceManager>(tag: (PreferenceManager).toString())
            .getString(PreferenceManager.keyFirebaseToken);
      }
      return await _storage.read(key: PreferenceManager.keyFirebaseToken) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> registerWithBackend() async {
    try {
      if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
        return;
      }
      final token = await read();
      if (token.isEmpty) return;
      await Get.find<AppRepository>(tag: (AppRepository).toString())
          .saveFirebaseToken(token);
    } catch (_) {}
  }

  static void openInboxFromPush(RemoteMessage message) {
    if (Get.context == null) return;
    Get.toNamed(Routes.NOTIFICATIONS);
  }
}
