import 'dart:io' show Platform;

/// Tuya IoT SDK configuration.
///
/// Get credentials from [Tuya IoT Platform](https://iot.tuya.com/):
/// 1. Create a project / app (iOS and Android can have different App Key/Secret)
/// 2. Get App Key and App Secret per platform from the project
/// 3. Download the security SDK (Android: security-algorithm.aar, iOS: ios_core_sdk)
///    and use the security key (Tuya Key) from the downloaded package
///
/// For production, pass these via dart-define or secure config;
/// do not commit real keys to version control.
class TuyaConfig {
  final String appKey;
  final String appSecret;
  final String securityKey;
  final bool isDebug;

  const TuyaConfig({
    required this.appKey,
    required this.appSecret,
    required this.securityKey,
    this.isDebug = true,
  });

  bool get isEnabled =>
      appKey.isNotEmpty && appSecret.isNotEmpty && securityKey.isNotEmpty;

  /// Create config from environment. Uses platform-specific keys when set,
  /// otherwise falls back to generic TUYA_APP_KEY / TUYA_APP_SECRET / TUYA_SECURITY_KEY.
  ///
  /// **Android:** `TUYA_APP_KEY_ANDROID`, `TUYA_APP_SECRET_ANDROID`, `TUYA_SECURITY_KEY_ANDROID`
  /// **iOS:** `TUYA_APP_KEY_IOS`, `TUYA_APP_SECRET_IOS`, `TUYA_SECURITY_KEY_IOS`
  /// **Fallback (both):** `TUYA_APP_KEY`, `TUYA_APP_SECRET`, `TUYA_SECURITY_KEY`
  factory TuyaConfig.fromEnvironment({
    String? appKey,
    String? appSecret,
    String? securityKey,
    bool isDebug = true,
  }) {
    final useIOS = _isIOS();
    return TuyaConfig(
      appKey: appKey ??
          _fromEnv(
            iosKey: 'je9nu97qnvvaagcrecvh',
            androidKey: 's4aasptj8tyr5h4eg3ds',
            fallbackKey: 'TUYA_APP_KEY',
            useIOS: useIOS,
          ),
      appSecret: appSecret ??
          _fromEnv(
            iosKey: 'exfkjxyat5yquf5jvmt88hkgjgechpmt',
            androidKey: 'jqv88gvkjepmje57qut9tgt7gk7u7fr3',
            fallbackKey: 'TUYA_APP_SECRET',
            useIOS: useIOS,
          ),
      securityKey: securityKey ??
          _fromEnv(
            iosKey: 'TUYA_SECURITY_KEY_IOS',
            androidKey: 'TUYA_SECURITY_KEY_ANDROID',
            fallbackKey: 'TUYA_SECURITY_KEY',
            useIOS: useIOS,
          ),
      isDebug: isDebug,
    );
  }

  static bool _isIOS() {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static String _fromEnv({
    required String iosKey,
    required String androidKey,
    required String fallbackKey,
    required bool useIOS,
  }) {
    final platformKey = useIOS ? iosKey : androidKey;
    final platformValue = String.fromEnvironment(platformKey, defaultValue: '');
    if (platformValue.isNotEmpty) return platformValue;
    return String.fromEnvironment(fallbackKey, defaultValue: '');
  }
}
