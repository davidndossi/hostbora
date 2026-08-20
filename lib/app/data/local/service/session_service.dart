import 'dart:async';

import 'package:get/get.dart';

import '../../model/login_response.dart';
import '../../repository/app_repository.dart';
import '../preference/preference_manager.dart';

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
    final refreshExpiry = await pref.getString(
      PreferenceManager.keyRefreshExpiryTime,
      defaultValue: '',
    );
    if (refreshToken.isEmpty || refreshExpiry.isEmpty) return false;
    final expiryMs = DateTime.tryParse(refreshExpiry)?.millisecondsSinceEpoch;
    if (expiryMs == null) return false;
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
    } catch (_) {
      return false;
    }
  }

  Future<void> saveFromLogin(LoginResponse response) async {
    final expiresIn = response.expiresIn ?? 0;
    if (response.token != null && expiresIn > 0) {
      final expiryTime = DateTime.now()
          .add(Duration(minutes: expiresIn))
          .toIso8601String();
      await _preferenceManager.setString(
        PreferenceManager.keyToken,
        response.token!,
      );
      await _preferenceManager.setString(
        PreferenceManager.keyExpiryTime,
        expiryTime,
      );
    }

    final refreshToken = response.refreshToken;
    final refreshExpiresIn = response.refreshExpiresIn ?? 0;
    if (refreshToken != null &&
        refreshToken.isNotEmpty &&
        refreshExpiresIn > 0) {
      final refreshExpiry = DateTime.now()
          .add(Duration(minutes: refreshExpiresIn))
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
  }

  Future<void> clearFullSession() => _preferenceManager.clearSession();
}
