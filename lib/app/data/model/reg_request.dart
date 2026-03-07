class RegRequest {
  RegRequest({
    String? firstName,
    String? middleName,
    String? surname,
    String? gender,
    String? mobileNumber,
    String? password,
  }){
    _firstName = firstName;
    _middleName = middleName;
    _surname = surname;
    _gender = gender;
    _mobileNumber = mobileNumber;
    _password = password;
  }

  RegRequest.fromJson(dynamic json) {
    _firstName = json['firstName'];
    _middleName = json['middleName'];
    _surname = json['surname'];
    _gender = json['gender'];
    _mobileNumber = json['mobileNumber'];
    _password = json['password'];
  }

  String? _firstName;
  String? _middleName;
  String? _surname;
  String? _gender;
  String? _mobileNumber;
  String? _password;

  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get surname => _surname;
  String? get gender => _gender;
  String? get mobileNumber => _mobileNumber;
  String? get password => _password;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['firstName'] = _firstName;
    map['middleName'] = _middleName;
    map['surname'] = _surname;
    map['gender'] = _gender;
    map['mobileNumber'] = _mobileNumber;
    map['password'] = _password;

    return map;
  }

}