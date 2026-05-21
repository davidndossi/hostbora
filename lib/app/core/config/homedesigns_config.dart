/// HomeDesigns.ai API configuration.
///
/// Obtain an access token from [API Board](https://homedesigns.ai/api-guide).
/// Do not commit real tokens — pass at build/run time:
///
/// ```bash
/// flutter run \
///   --dart-define=HOMEDESIGNS_ACCESS_TOKEN=your_token_here
/// ```
///
/// Optional base URL override (defaults to v2):
/// `--dart-define=HOMEDESIGNS_API_BASE_URL=https://homedesigns.ai/api/v2`
class HomeDesignsConfig {
  static const String defaultApiBaseUrl = 'https://homedesigns.ai/api/v2';
  static const String webAppUrl = 'https://homedesigns.ai/';
  static const String apiGuideUrl = 'https://homedesigns.ai/api-guide';

  final String accessToken;
  final String apiBaseUrl;

  const HomeDesignsConfig({
    required this.accessToken,
    this.apiBaseUrl = defaultApiBaseUrl,
  });

  bool get isConfigured => accessToken.trim().isNotEmpty;

  factory HomeDesignsConfig.fromEnvironment() {
    return HomeDesignsConfig(
      accessToken: const String.fromEnvironment(
        'HOMEDESIGNS_ACCESS_TOKEN',
        defaultValue: '',
      ),
      apiBaseUrl: _normalizeBaseUrl(
        const String.fromEnvironment(
          'HOMEDESIGNS_API_BASE_URL',
          defaultValue: defaultApiBaseUrl,
        ),
      ),
    );
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return defaultApiBaseUrl;
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
