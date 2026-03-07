class SendSmsRequest {
  SendSmsRequest({
    String? phoneNumber,
    String? message,
  }) {
    _phoneNumber = phoneNumber;
    _message = message;
  }

  SendSmsRequest.fromJson(dynamic json) {
    _phoneNumber = json['phoneNumber'];
    _message = json['message'];
  }

  String? _phoneNumber;
  String? _message;

  String? get phoneNumber => _phoneNumber;
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phoneNumber'] = _phoneNumber;
    map['message'] = _message;
    return map;
  }
}
