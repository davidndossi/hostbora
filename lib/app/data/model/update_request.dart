import 'relationship.dart';

class UpdateRequest {
  UpdateRequest({
    String? gender,
    String? phoneNumber,
    String? emailAddress,
    String? photo,
    String? signature,
    String? dob,
    String? maritalStatus,
    String? employmentStatus,
    String? occupation,
    String? employer,
    String? birthRegion,
    String? birthDistrict,
    String? birthWard,
    String? birthPlace,
    String? residenceRegion,
    String? residenceDistrict,
    String? residenceArea,
    String? residenceHouseNo,
    String? postalAddress,
    String? otherPhoneNumber,
    String? spouseName,
    String? neighbour,
    String? representative,
    List<Relationship>? relationships
  }){
    _gender = gender;
    _mobileNumber = phoneNumber;
    _emailAddress = emailAddress;
    _photo = photo;
    _signature = signature;
    _dateOfBirth = dob;
    _maritalStatus = maritalStatus;
    _employmentStatus = employmentStatus;
    _occupation = occupation;
    _employer = employer;
    _birthRegion = birthRegion;
    _birthDistrict = birthDistrict;
    _birthWard = birthWard;
    _birthPlace = birthPlace;
    _addressLine1 = residenceRegion;
    _addressLine2 = residenceDistrict;
    _addressLine3 = residenceArea;
    _addressLine4 = residenceHouseNo;
    _postalAddress = postalAddress;
    _otherMobileNumber = otherPhoneNumber;
    _spouseName = spouseName;
    _neighbour = neighbour;
    _representative = representative;
    _relationships = relationships;
  }

  UpdateRequest.fromJson(dynamic json) {
    _gender = json['gender'];
    _mobileNumber = json['msisdn'];
    _emailAddress = json['emailAddress'];
    _photo = json['photo'];
    _signature = json['signature'];
    _dateOfBirth = json['dob'];
    _maritalStatus = json['maritalStatus'];
    _employmentStatus = json['employmentStatus'];
    _occupation = json['occupation'];
    _employer = json['employer'];
    _birthRegion = json['birthRegion'];
    _birthDistrict = json['birthDistrict'];
    _birthWard = json['birthWard'];
    _birthPlace = json['birthPlace'];
    _addressLine1 = json['residenceRegion'];
    _addressLine2 = json['residenceDistrict'];
    _addressLine3 = json['residenceArea'];
    _addressLine4 = json['residenceHouseNo'];
    _postalAddress = json['postalAddress'];
    _otherMobileNumber = json['otherPhoneNumber'];
    _spouseName = json['spouseName'];
    _neighbour = json['neighbour'];
    _representative = json['representative'];
    _relationships = List<Relationship>.from(json['relationships'].map((relationship) => relationship.toJson()));
  }

  String? _gender;
  String? _mobileNumber;
  String? _emailAddress;
  String? _photo;
  String? _signature;
  String? _dateOfBirth;
  String? _maritalStatus;
  String? _employmentStatus;
  String? _occupation;
  String? _employer;
  String? _birthRegion;
  String? _birthDistrict;
  String? _birthWard;
  String? _birthPlace;
  String? _addressLine1;
  String? _addressLine2;
  String? _addressLine3;
  String? _addressLine4;
  String? _postalAddress;
  String? _otherMobileNumber;
  String? _spouseName;
  String? _neighbour;
  String? _representative;
  List<Relationship>? _relationships;

  String? get gender => _gender;
  String? get mobileNumber => _mobileNumber;
  String? get emailAddress => _emailAddress;
  String? get photo => _photo;
  String? get signature => _signature;
  String? get dateOfBirth => _dateOfBirth;
  String? get maritalStatus => _maritalStatus;
  String? get employmentStatus => _employmentStatus;
  String? get occupation => _occupation;
  String? get employer => _employer;
  String? get birthRegion => _birthRegion;
  String? get birthDistrict => _birthDistrict;
  String? get birthWard => _birthWard;
  String? get birthPlace => _birthPlace;
  String? get addressLine1 => _addressLine1;
  String? get addressLine2 => _addressLine2;
  String? get addressLine3 => _addressLine3;
  String? get addressLine4 => _addressLine4;
  String? get postalAddress => _postalAddress;
  String? get otherMobileNumber => _otherMobileNumber;
  String? get spouseName => _spouseName;
  String? get neighbour => _neighbour;
  String? get representative => _representative;
  List<Relationship>? get relationships => _relationships;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['gender'] = _gender;
    map['msisdn'] = _mobileNumber;
    map['emailAddress'] = _emailAddress;
    map['photo'] = _photo;
    map['signature'] = _signature;
    map['dob'] = _dateOfBirth;
    map['maritalStatus'] = _maritalStatus;
    map['employmentStatus'] = _employmentStatus;
    map['occupation'] = _occupation;
    map['employer'] = _employer;
    map['birthRegion'] = _birthRegion;
    map['birthDistrict'] = _birthDistrict;
    map['birthWard'] = _birthWard;
    map['birthPlace'] = _birthPlace;
    map['residenceRegion'] = _addressLine1;
    map['residenceDistrict'] = _addressLine2;
    map['residenceArea'] = _addressLine3;
    map['residenceHouseNo'] = _addressLine4;
    map['postalAddress'] = _postalAddress;
    map['otherPhoneNumber'] = _otherMobileNumber;
    map['spouseName'] = _spouseName;
    map['neighbour'] = _neighbour;
    map['representative'] = _representative;
    map['relationships'] = _relationships != null ?
    List.from(_relationships!.map((relationship) => relationship.toJson())) : [];

    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }

}