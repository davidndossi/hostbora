import '../../model/community.dart';
import '../../model/login_response.dart';

abstract class PreferenceManager {
  static const keyToken = 'token';
  static const keyExpiryTime = 'expiry_time';
  static const keyRefreshToken = 'refresh_token';
  static const keyRefreshExpiryTime = 'refresh_expiry_time';
  static const keyFirstLogin = 'first_login';
  static const keyUsername = 'username';

  /// User id that owns the on-device SQLite and GetStorage data.
  /// Logout keeps this so the same person can sign back in offline.
  /// Account deletion and a different sign-in clear it with the data.
  static const keyLocalDataOwnerUserId = 'local_data_owner_user_id';
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

  /// Default app-lock idle timeout. Settings, bootstrap, and lifecycle must share this.
  static const defaultAppLockTimeoutSeconds = 300;
  static const keyAppBackgroundedAtMs = 'app_backgrounded_at_ms';
  static const keyHasSeenPropertiesTabSpotlight =
      'has_seen_properties_tab_spotlight';

  /// Home workspace chip: `all` | `bnb` | `rent`.
  static const keyHomeWorkspaceFilter = 'home_workspace_filter';
  static const keyHomeHideAmounts = 'home_hide_amounts';

  /// First time this device saw at least one property (for Home first-week stage).
  static const keyFirstPropertyAtMs = 'first_property_at_ms';

  /// Set once Home Get started (property + occupant + payment) is finished.
  static const keyHomeGetStartedComplete = 'home_get_started_complete';

  /// Set once the `first_payment_recorded` analytics milestone has been sent,
  /// so the activation event is only ever reported once per install.
  static const keyFirstPaymentLogged = 'first_payment_logged';

  /// True between a successful sign-up and the host either adding or skipping
  /// their first property. Survives the PIN screen, which sits between the two.
  static const keyPendingFirstProperty = 'pending_first_property';

  /// First name captured during sign-up, used to pre-fill the first property
  /// as "{name}'s Apartment" before any profile sync has run.
  static const keySignupFirstName = 'signup_first_name';

  static const keyHasSeenPropertiesCoachMark = 'has_seen_properties_coach_mark';
  static const keyHasSeenFinancesCoachMark = 'has_seen_finances_coach_mark';
  static const keyHasDismissedHomeAiInsight = 'has_dismissed_home_ai_insight';

  /// Portfolio manager mode: host user id we write/manage under.
  static const keyActingAsHostUserId = 'acting_as_host_user_id';
  static const keyManagedHostName = 'managed_host_name';
  static const keyIsPortfolioManager = 'is_portfolio_manager';

  /// Restricted staff session. Absent/false means owner or portfolio manager.
  static const keyStaffRestricted = 'staff_restricted';
  static const keyStaffPermissions = 'staff_permissions';
  static const keyStaffAllProperties = 'staff_all_properties';
  static const keyStaffPropertyRefs = 'staff_property_refs';

  /// JSON map of taskId → {assignee, status} when the API list omits them.
  static const keyTaskAssignmentOverrides = 'task_assignment_overrides';

  /// Full task snapshots keyed by id, including the staff phone, so a staff
  /// login can show assignments the task API does not return for that user.
  static const keyAssignedTaskInbox = 'assigned_task_inbox_v1';

  /// Income row ids whose amount has already been added onto a lease end.
  static const keyLeaseExtensionAppliedIncome =
      'lease_extension_applied_income_v1';

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
