class OtpResponse {
  OtpResponse({
    String? respCode,
    String? respMsg,
    String? token
  }){
    _respCode = respCode;
    _respMsg = respMsg;
    _token = token;
  }

  OtpResponse.fromJson(dynamic json) {
    _respCode = json['respCode'];
    _respMsg = json['respMsg'];
    _token = json['token'];
  }

  String? _respCode;
  String? _respMsg;
  String? _token;

  String? get respCode => _respCode;
  String? get respMsg => _respMsg;
  String? get token => _token;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['respCode'] = _respCode;
    map['respMsg'] = _respMsg;
    map['token'] = _token;
    return map;
  }
}