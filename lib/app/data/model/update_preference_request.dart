class UpdatePreferenceRequest {
  UpdatePreferenceRequest({
      String? theme, 
      String? notifications, 
      String? language, 
      String? privacy,
      String? baseCurrency
  }){
    _theme = theme;
    _notifications = notifications;
    _language = language;
    _privacy = privacy;
    _baseCurrency = baseCurrency;
  }

  UpdatePreferenceRequest.fromJson(dynamic json) {
    _theme = json['theme'];
    _notifications = json['notifications'];
    _language = json['language'];
    _privacy = json['privacy'];
    _baseCurrency = json['baseCurrency'] ?? json['base_currency'] ?? json['currency'];
  }

  String? _theme;
  String? _notifications;
  String? _language;
  String? _privacy;
  String? _baseCurrency;

  UpdatePreferenceRequest copyWith({
    String? theme,
    String? notifications,
    String? language,
    String? privacy,
    String? baseCurrency,
  }) => UpdatePreferenceRequest(
    theme: theme ?? _theme,
    notifications: notifications ?? _notifications,
    language: language ?? _language,
    privacy: privacy ?? _privacy,
    baseCurrency: baseCurrency ?? _baseCurrency,
  );

  String? get theme => _theme;
  String? get notifications => _notifications;
  String? get language => _language;
  String? get privacy => _privacy;
  String? get baseCurrency => _baseCurrency;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_theme != null) map['theme'] = _theme;
    if (_notifications != null) map['notifications'] = _notifications;
    if (_language != null) map['language'] = _language;
    if (_privacy != null) map['privacy'] = _privacy;
    if (_baseCurrency != null && _baseCurrency!.trim().isNotEmpty) {
      final code = _baseCurrency!.trim().toUpperCase();
      // Backend / web use `currency`; keep `baseCurrency` for older handlers.
      map['currency'] = code;
      map['baseCurrency'] = code;
    }
    return map;
  }

}