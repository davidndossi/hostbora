class RegRequest {
  RegRequest({
    String? firstName,
    String? middleName,
    String? surname,
    String? gender,
    String? mobileNumber,
    String? email,
    String? password,
    String? referralCode,
    String? channel,
  }) {
    _firstName = firstName;
    _middleName = middleName;
    _surname = surname;
    _gender = gender;
    _mobileNumber = mobileNumber;
    _email = email;
    _password = password;
    _referralCode = referralCode;
    _channel = channel;
  }

  RegRequest.fromJson(dynamic json) {
    _firstName = json['firstName'];
    _middleName = json['middleName'];
    _surname = json['surname'];
    _gender = json['gender'];
    _mobileNumber = json['mobileNumber'];
    _email = json['email'];
    _password = json['password'];
    _referralCode = json['referralCode'] ?? json['referral_code'];
    _channel = json['channel'];
  }

  String? _firstName;
  String? _middleName;
  String? _surname;
  String? _gender;
  String? _mobileNumber;
  String? _email;
  String? _password;
  String? _referralCode;
  String? _channel;

  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get surname => _surname;
  String? get gender => _gender;
  String? get mobileNumber => _mobileNumber;
  String? get email => _email;
  String? get password => _password;
  String? get referralCode => _referralCode;
  String? get channel => _channel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['firstName'] = _firstName;
    map['middleName'] = _middleName;
    map['surname'] = _surname;
    map['gender'] = _gender;
    map['mobileNumber'] = _mobileNumber;
    map['email'] = _email;
    // Passwordless: omit password unless a legacy client still sends one.
    if (_password != null && _password!.isNotEmpty) {
      map['password'] = _password;
    }
    if (_channel != null && _channel!.isNotEmpty) {
      map['channel'] = _channel;
    }
    if (_referralCode != null && _referralCode!.trim().isNotEmpty) {
      map['referralCode'] = _referralCode!.trim().toUpperCase();
    }

    return map;
  }
}