import 'package:logger/logger.dart';

import '/app/core/values/app_values.dart';

class EnvConfig {
  final String appName;
  final String baseUrl;
  final bool shouldCollectCrashLog;
  /// AzamPay (push-to-pay). Optional; if null, feature is disabled.
  final String? azamPayAppName;
  final String? azamPayClientId;
  final String? azamPayClientSecret;
  /// Use AzamPay sandbox (default true when credentials are set).
  final bool azamPaySandbox;

  late final Logger logger;

  bool get isAzamPayConfigured =>
      (azamPayAppName?.trim().isNotEmpty ?? false) &&
      (azamPayClientId?.trim().isNotEmpty ?? false) &&
      (azamPayClientSecret?.trim().isNotEmpty ?? false);

  EnvConfig({
    required this.appName,
    required this.baseUrl,
    this.shouldCollectCrashLog = false,
    this.azamPayAppName,
    this.azamPayClientId,
    this.azamPayClientSecret,
    this.azamPaySandbox = true,
  }) {
    logger = Logger(
      printer: PrettyPrinter(
        methodCount: AppValues.loggerMethodCount,
        // number of method calls to be displayed
        errorMethodCount: AppValues.loggerErrorMethodCount,
        // number of method calls if stacktrace is provided
        lineLength: AppValues.loggerLineLength,
        // width of the output
        colors: true,
        // Colorful log messages
        printEmojis: true,
        // Print an emoji for each log message
        dateTimeFormat: DateTimeFormat.none
      ),
    );
  }
}
