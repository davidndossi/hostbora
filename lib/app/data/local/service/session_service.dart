import 'dart:async';

import 'package:get/get.dart';

import '../../../core/access/staff_access.dart';
import '../../../network/exceptions/unauthorize_exception.dart';
import '../../model/login_response.dart';
import '../../repository/app_repository.dart';
import '../../service/fcm_token_service.dart';
import '../preference/preference_manager.dart';
import 'local_account_data_reset.dart';

/// Keeps users signed in with long-lived refresh tokens (login-once UX).
class SessionService extends GetxService {
  SessionService(this._preferenceManager);

  final PreferenceManager _preferenceManager;
  Future<bool>? _refreshInFlight;

  static Future<bool> hasLocalSession(PreferenceManager pref) async {
    if (await _isAccessTokenValid(pref)) return true;
    return _isRefreshTokenValid(pref);
  }

  static Future<bool> _isAccessTokenValid(PreferenceManager pref) async {
    final token = await pref.getString(
      PreferenceManager.keyToken,
      defaultValue: '',
    );
    final expiryTime = await pref.getString(
      PreferenceManager.keyExpiryTime,
      defaultValue: '',
    );
    if (token.isEmpty || expiryTime.isEmpty) return false;
    final expiryMs = DateTime.tryParse(expiryTime)?.millisecondsSinceEpoch;
    if (expiryMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch <= expiryMs;
  }

  static Future<bool> _isRefreshTokenValid(PreferenceManager pref) async {
    final refreshToken = await pref.getString(
      PreferenceManager.keyRefreshToken,
      defaultValue: '',
    );
    if (refreshToken.isEmpty) return false;
    final refreshExpiry = await pref.getString(
      PreferenceManager.keyRefreshExpiryTime,
      defaultValue: '',
    );
    // Token without a stored expiry is still usable (older app builds).
    if (refreshExpiry.isEmpty) return true;
    final expiryMs = DateTime.tryParse(refreshExpiry)?.millisecondsSinceEpoch;
    if (expiryMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch <= expiryMs;
  }

  Future<bool> hasPersistedSession() =>
      SessionService.hasLocalSession(_preferenceManager);

  Future<bool> isAccessTokenValid() =>
      _isAccessTokenValid(_preferenceManager);

  /// Ensures a usable access token.
  ///
  /// When [forceRefresh] is true (e.g. after a 401/403 from the API), always
  /// attempt a refresh even if the locally stored access-token expiry has not
  /// elapsed — the server may have rejected the token for clock skew, secret
  /// rotation, or an earlier expiry than the client tracked.
  Future<bool> ensureValidSession({bool forceRefresh = false}) async {
    if (!forceRefresh && await isAccessTokenValid()) return true;
    return _refreshAccessToken();
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshInFlight != null) return _refreshInFlight!;
    _refreshInFlight = _doRefreshAccessToken();
    try {
      return await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _doRefreshAccessToken() async {
    if (!await _isRefreshTokenValid(_preferenceManager)) return false;
    final refreshToken = await _preferenceManager.getString(
      PreferenceManager.keyRefreshToken,
      defaultValue: '',
    );
    if (refreshToken.isEmpty) return false;

    try {
      if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
        return false;
      }
      final repository =
          Get.find<AppRepository>(tag: (AppRepository).toString());
      final response = await repository.refreshSession(refreshToken);
      if (response.message != 'auth_success' || response.token == null) {
        return false;
      }
      await saveFromLogin(response);
      return true;
    } on UnauthorizedException {
      // Server rejected the refresh token. Drop it so later calls do not
      // keep posting the same dead token.
      await clearFullSession();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveFromLogin(LoginResponse response) async {
    final accessToken = response.token;
    if (accessToken != null && accessToken.isNotEmpty) {
      final expiresIn =
          (response.expiresIn != null && response.expiresIn! > 0)
              ? response.expiresIn!
              : _defaultAccessTtlMinutes;
      final expiryTime = DateTime.now()
          .add(Duration(minutes: expiresIn))
          .toIso8601String();
      await _preferenceManager.setString(
        PreferenceManager.keyToken,
        accessToken,
      );
      await _preferenceManager.setString(
        PreferenceManager.keyExpiryTime,
        expiryTime,
      );
    }

    final refreshToken = response.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final refreshExpiry = DateTime.now()
          .add(_refreshTtl(response.refreshExpiresIn))
          .toIso8601String();
      await _preferenceManager.setString(
        PreferenceManager.keyRefreshToken,
        refreshToken,
      );
      await _preferenceManager.setString(
        PreferenceManager.keyRefreshExpiryTime,
        refreshExpiry,
      );
    }

    if (response.user != null) {
      final nextUserId = response.user?.id?.trim() ?? '';
      if (nextUserId.isNotEmpty) {
        await LocalAccountDataReset.alignToUser(
          _preferenceManager,
          userId: nextUserId,
        );
      }
      await _preferenceManager.setUser('user', response.user);
      if (response.user?.msisdn != null) {
        await _preferenceManager.setString(
          PreferenceManager.keyUsername,
          response.user!.msisdn!,
        );
      }
      if (response.user?.fullName != null) {
        await _preferenceManager.setString(
          PreferenceManager.keyFullName,
          response.user!.fullName!,
        );
      }
      if (response.user?.roles != null) {
        await _preferenceManager.setStringList(
          PreferenceManager.keyRoles,
          response.user!.roles!,
        );
      }
      await _preferenceManager.setBool(
        'isAdmin',
        response.user?.isAdmin ?? false,
      );
    }
    if (Get.isRegistered<StaffAccessStore>() && response.hasStaffFlag) {
      await Get.find<StaffAccessStore>().applyPayload({
        'staffRestricted': response.staffRestricted == true,
        'staffPermissions': response.staffPermissions,
        'propertyScope': response.propertyScope,
      });
    }
    FcmTokenService.registerWithBackend();
  }

  Future<void> clearFullSession() async {
    await _preferenceManager.clearSession();
    if (Get.isRegistered<StaffAccessStore>()) {
      await Get.find<StaffAccessStore>().applyUnrestricted();
    }
  }

  /// Access token lifetime in minutes. Matches `jwt-security.expiration-time` (90 days).
  static const _defaultAccessTtlMinutes = 90 * 24 * 60;

  /// API sends minutes (`90 * 24 * 60`). Some builds sent days (`90`).
  static Duration _refreshTtl(int? raw) {
    if (raw == null || raw <= 0) return const Duration(days: 90);
    if (raw < 24 * 60) return Duration(days: raw);
    return Duration(minutes: raw);
  }
}
