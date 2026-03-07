class ChangePasswordRequest {
  ChangePasswordRequest({
    String? username,
    String? password,
    String? deviceId,
    String? newPassword1,
    String? newPassword2
  }){
    _username = username;
    _password = password;
    _deviceId = deviceId;
    _newPassword1 = newPassword1;
    _newPassword2 = newPassword2;
  }

  ChangePasswordRequest.fromJson(dynamic json) {
    _username = json['username'];
    _password = json['password'];
    _deviceId = json['deviceId'];
    _newPassword1 = json['newPassword1'];
    _newPassword2 = json['newPassword2'];
  }

  String? _username;
  String? _password;
  String? _deviceId;
  String? _newPassword1;
  String? _newPassword2;

  String? get username => _username;
  String? get password => _password;
  String? get deviceId => _deviceId;
  String? get newPassword1 => _newPassword1;
  String? get newPassword2 => _newPassword2;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['username'] = _username;
    map['password'] = _password;
    map['deviceId'] = _deviceId;
    map['newPassword1'] = _newPassword1;
    map['newPassword2'] = _newPassword2;

    return map;
  }

}