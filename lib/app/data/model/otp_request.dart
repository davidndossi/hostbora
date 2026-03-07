class OtpRequest {
  OtpRequest({
    String? email,
    String? msisdn,
    String? otp
  }){
    _email = email;
    _msisdn = msisdn;
    _otp = otp;
  }

  OtpRequest.fromJson(dynamic json) {
    _email = json['email'];
    _msisdn = json['msisdn'];
    _otp = json['otp'];
  }

  String? _email;
  String? _msisdn;
  String? _otp;

  String? get email => _email;
  String? get msisdn => _msisdn;
  String? get otp => _otp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['email'] = _email;
    map['msisdn'] = _msisdn;
    map['otp'] = _otp;
    return map;
  }
}