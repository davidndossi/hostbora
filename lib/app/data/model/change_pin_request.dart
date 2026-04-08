class ChangePinRequest {
  ChangePinRequest({
    String? msisdn,
    String? oldPin,
    String? newPin
  }){
    _msisdn = msisdn;
    _oldPin = oldPin;
    _newPin = newPin;
  }

  ChangePinRequest.fromJson(dynamic json) {
    _msisdn = json['msisdn'];
    _oldPin = json['oldPin'];
    _newPin = json['newPin'];
  }

  String? _msisdn;
  String? _oldPin;
  String? _newPin;

  String? get username => _msisdn;
  String? get oldPin => _oldPin;
  String? get newPin => _newPin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msisdn'] = _msisdn;
    map['oldPin'] = _oldPin;
    map['newPin'] = _newPin;

    return map;
  }

}