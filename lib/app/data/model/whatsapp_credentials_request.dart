class WhatsAppCredentialsRequest {
  WhatsAppCredentialsRequest({
    required String apiKey,
    required String phoneNumberId,
    String? phoneNumber,
    String? provider,
  }) {
    _apiKey = apiKey;
    _phoneNumberId = phoneNumberId;
    _phoneNumber = phoneNumber;
    _provider = provider;
  }

  String? _apiKey;
  String? _phoneNumberId;
  String? _phoneNumber;
  String? _provider;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'apiKey': _apiKey,
      'phoneNumberId': _phoneNumberId,
    };
    if (_phoneNumber != null && _phoneNumber!.trim().isNotEmpty) {
      map['phoneNumber'] = _phoneNumber;
    }
    if (_provider != null && _provider!.trim().isNotEmpty) {
      map['provider'] = _provider;
    }
    return map;
  }
}
