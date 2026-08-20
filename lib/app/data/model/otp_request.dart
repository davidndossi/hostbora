class OtpRequest {
  OtpRequest({
    String? email,
    String? msisdn,
    String? otp,
    String? flow,
    String? channel,
  }) {
    _email = email;
    _msisdn = msisdn;
    _otp = otp;
    _flow = flow;
    _channel = channel;
  }

  OtpRequest.fromJson(dynamic json) {
    _email = json['email'];
    _msisdn = json['msisdn'];
    _otp = json['otp'];
    _flow = json['flow'];
    _channel = json['channel'];
  }

  String? _email;
  String? _msisdn;
  String? _otp;
  String? _flow;
  String? _channel;

  String? get email => _email;
  String? get msisdn => _msisdn;
  String? get otp => _otp;
  String? get flow => _flow;
  String? get channel => _channel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['email'] = _email;
    map['msisdn'] = _msisdn;
    map['otp'] = _otp;
    if (_flow != null && _flow!.isNotEmpty) {
      map['flow'] = _flow;
    }
    if (_channel != null && _channel!.isNotEmpty) {
      map['channel'] = _channel;
    }
    return map;
  }
}