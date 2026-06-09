class AppVersionResponse {
  const AppVersionResponse({
    required this.latestVersion,
    required this.minVersion,
    this.forceUpdate = false,
    this.updateUrl,
    this.releaseNotes,
  });

  /// e.g. "1.2.0"
  final String latestVersion;

  /// Oldest version still allowed to run; if installed < minVersion, force update.
  final String minVersion;

  /// When true the user cannot dismiss the dialog.
  final bool forceUpdate;

  /// Deep link to Play Store / App Store / direct APK.
  final String? updateUrl;

  /// Short human-readable changelog snippet.
  final String? releaseNotes;

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      latestVersion: (json['latestVersion'] as String? ?? '').trim(),
      minVersion: (json['minVersion'] as String? ?? '').trim(),
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      updateUrl: json['updateUrl'] as String?,
      releaseNotes: json['releaseNotes'] as String?,
    );
  }
}
