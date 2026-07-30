class UpdatePreferenceRequest {
  UpdatePreferenceRequest({
      String? theme, 
      String? notifications, 
      String? language, 
      String? privacy, 
      bool? receiveCommunityUpdates, 
      bool? eventReminders, 
      bool? deathAnnouncements,
      String? baseCurrency,
  }){
    _theme = theme;
    _notifications = notifications;
    _language = language;
    _privacy = privacy;
    _receiveCommunityUpdates = receiveCommunityUpdates;
    _eventReminders = eventReminders;
    _deathAnnouncements = deathAnnouncements;
    _baseCurrency = baseCurrency;
  }

  UpdatePreferenceRequest.fromJson(dynamic json) {
    _theme = json['theme'];
    _notifications = json['notifications'];
    _language = json['language'];
    _privacy = json['privacy'];
    _receiveCommunityUpdates = json['receiveCommunityUpdates'];
    _eventReminders = json['eventReminders'];
    _deathAnnouncements = json['deathAnnouncements'];
    _baseCurrency = json['baseCurrency'] ?? json['base_currency'];
  }

  String? _theme;
  String? _notifications;
  String? _language;
  String? _privacy;
  bool? _receiveCommunityUpdates;
  bool? _eventReminders;
  bool? _deathAnnouncements;
  String? _baseCurrency;

  UpdatePreferenceRequest copyWith({
    String? theme,
    String? notifications,
    String? language,
    String? privacy,
    bool? receiveCommunityUpdates,
    bool? eventReminders,
    bool? deathAnnouncements,
    String? baseCurrency,
  }) => UpdatePreferenceRequest(
    theme: theme ?? _theme,
    notifications: notifications ?? _notifications,
    language: language ?? _language,
    privacy: privacy ?? _privacy,
    receiveCommunityUpdates: receiveCommunityUpdates ?? _receiveCommunityUpdates,
    eventReminders: eventReminders ?? _eventReminders,
    deathAnnouncements: deathAnnouncements ?? _deathAnnouncements,
    baseCurrency: baseCurrency ?? _baseCurrency,
  );

  String? get theme => _theme;
  String? get notifications => _notifications;
  String? get language => _language;
  String? get privacy => _privacy;
  bool? get receiveCommunityUpdates => _receiveCommunityUpdates;
  bool? get eventReminders => _eventReminders;
  bool? get deathAnnouncements => _deathAnnouncements;
  String? get baseCurrency => _baseCurrency;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['theme'] = _theme;
    map['notifications'] = _notifications;
    map['language'] = _language;
    map['privacy'] = _privacy;
    map['receiveCommunityUpdates'] = _receiveCommunityUpdates;
    map['eventReminders'] = _eventReminders;
    map['deathAnnouncements'] = _deathAnnouncements;
    if (_baseCurrency != null && _baseCurrency!.trim().isNotEmpty) {
      map['baseCurrency'] = _baseCurrency!.trim().toUpperCase();
    }
    return map;
  }

}