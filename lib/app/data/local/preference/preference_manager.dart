import '../../model/community.dart';
import '../../model/login_response.dart';

abstract class PreferenceManager {
  static const keyToken = 'token';
  static const keyExpiryTime = 'expiry_time';
  static const keyRefreshToken = 'refresh_token';
  static const keyRefreshExpiryTime = 'refresh_expiry_time';
  static const keyFirstLogin = 'first_login';
  static const keyUsername = 'username';
  static const keyFullName = 'full_name';
  static const keyDeviceId = 'device_id';
  static const keyRoles = 'roles';
  static const keyFirebaseToken = 'fcm_token';
  static const keyLang = 'language';
  static const keyWorkspaceType = 'workspace_type';
  static const keyBaseCurrency = 'base_currency';
  static const keyPinCode = 'pin_code';
  static const keyPinEnabled = 'pin_enabled';
  static const keyPinFailedAttempts = 'pin_failed_attempts';
  static const keyPinLockedUntilMs = 'pin_locked_until_ms';
  static const keyFaceIdEnabled = 'face_id_enabled';
  static const keyAppLockTimeoutSeconds = 'app_lock_timeout_seconds';
  static const keyAppBackgroundedAtMs = 'app_backgrounded_at_ms';
  static const keyHasSeenPropertiesTabSpotlight =
      'has_seen_properties_tab_spotlight';

  /// Home workspace chip: `all` | `bnb` | `rent`.
  static const keyHomeWorkspaceFilter = 'home_workspace_filter';

  /// First time this device saw at least one property (for Home first-week stage).
  static const keyFirstPropertyAtMs = 'first_property_at_ms';

  static const keyHasSeenPropertiesCoachMark = 'has_seen_properties_coach_mark';
  static const keyHasSeenFinancesCoachMark = 'has_seen_finances_coach_mark';
  static const keyHasDismissedHomeAiInsight = 'has_dismissed_home_ai_insight';

  Future<String> getString(String key, {String defaultValue = ''});

  Future<bool> setString(String key, String value);

  Future<int> getInt(String key, {int defaultValue = 0});

  Future<bool> setInt(String key, int value);

  Future<double> getDouble(String key, {double defaultValue = 0.0});

  Future<bool> setDouble(String key, double value);

  Future<bool> getBool(String key, {bool defaultValue = false});

  Future<bool> setBool(String key, bool value);

  Future<User> getUser();

  Future<bool> setUser(String key, User? value);

  Future<List<String>> getStringList(
    String key, {
    List<String> defaultValue = const [],
  });

  Future<bool> setStringList(String key, List<String> value);

  Future<bool> remove(String key);

  Future<bool> clear();

  void saveUserCommunities(List<Community> items);

  Future<List<Community>> getUserCommunities();

  Future<void> clearSession();
}
