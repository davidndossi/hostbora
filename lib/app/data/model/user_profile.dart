import 'user_community.dart';
import 'relationship.dart';

class UserProfile {
  UserProfile({
    String? userId,
    String? profilePicture,
    String? fullName,
    Address? address,
    String? gender,
    String? email,
    String? bio,
    String? spouseName,
    List<UserCommunity>? communities,
    List<Relationship>? relatives,
    List<Relationship>? nextOfKin,
    List<Relationship>? neighbours,
    String? occupation,
    String? maritalStatus,
    String? privacy,
    bool? receiveCommunityUpdates,
    bool? eventReminders,
    bool? deathAnnouncements,
    bool? isLeader,
    bool? isAdmin
  }) {
    _userId = userId;
    _profilePicture = profilePicture;
    _fullName = fullName;
    _address = address;
    _gender = gender;
    _email = email;
    _bio = bio;
    _spouseName = spouseName;
    _communities = communities;
    _relatives = relatives;
    _nextOfKin = nextOfKin;
    _neighbours = neighbours;
    _occupation = occupation;
    _maritalStatus = maritalStatus;
    _privacy = privacy;
    _receiveCommunityUpdates = receiveCommunityUpdates;
    _eventReminders = eventReminders;
    _deathAnnouncements = deathAnnouncements;
    _isLeader = isLeader;
    _isAdmin = isAdmin;
  }

  UserProfile.fromJson(dynamic json) {
    _userId = json['userId'];
    _profilePicture = json['profilePicture'];
    _fullName = json['fullName'];
    _spouseName = json['spouseName'];
    print(json['address']);
    _address = json['address'] != null ? Address.fromJson(json['address']) : null;
    if (json['communities'] != null) {
      _communities = [];
      json['communities'].forEach((v) {
        _communities?.add(UserCommunity.fromJson(v));
      });
    }
    if (json['relatives'] != null) {
      _relatives = [];
      json['relatives'].forEach((v) {
        _relatives?.add(Relationship.fromJson(v));
      });
    }
    if (json['nextOfKin'] != null) {
      _nextOfKin = [];
      json['nextOfKin'].forEach((v) {
        _nextOfKin?.add(Relationship.fromJson(v));
      });
    }
    if (json['neighbours'] != null) {
      _neighbours = [];
      json['neighbours'].forEach((v) {
        _neighbours?.add(Relationship.fromJson(v));
      });
    }
    _occupation = json['occupation'];
    _gender = json['gender'];
    _email = json['email'];
    _bio = json['bio'];
    _maritalStatus = json['maritalStatus'];
    _privacy = json['privacy'];
    _receiveCommunityUpdates = json['receiveCommunityUpdates'];
    _eventReminders = json['eventReminders'];
    _deathAnnouncements = json['deathAnnouncements'];
    _isLeader = json['isLeader'];
    _isAdmin = json['isAdmin'];
  }

  String? _userId;
  String? _profilePicture;
  String? _fullName;
  Address? _address;
  String? _gender;
  String? _email;
  String? _bio;
  String? _spouseName;
  List<UserCommunity>? _communities;
  List<Relationship>? _relatives;
  List<Relationship>? _nextOfKin;
  List<Relationship>? _neighbours;
  String? _occupation;
  String? _maritalStatus;
  String? _privacy;
  bool? _receiveCommunityUpdates;
  bool? _eventReminders;
  bool? _deathAnnouncements;
  bool? _isLeader;
  bool? _isAdmin;

  UserProfile copyWith({  String? userId,
    String? profilePicture,
    String? fullName,
    Address? address,
    String? gender,
    String? email,
    String? bio,
    String? spouseName,
    List<UserCommunity>? communities,
    List<Relationship>? relatives,
    List<Relationship>? nextOfKin,
    List<Relationship>? neighbours,
    String? occupation,
    String? maritalStatus,
    String? privacy,
    bool? receiveCommunityUpdates,
    bool? eventReminders,
    bool? deathAnnouncements,
    bool? isLeader,
    bool? isAdmin,
  }) => UserProfile(  userId: userId ?? _userId,
    profilePicture: profilePicture ?? _profilePicture,
    fullName: fullName ?? _fullName,
    address: address ?? _address,
    gender: gender ?? _gender,
    email: email ?? _email,
    bio: bio ?? _bio,
    spouseName: spouseName ?? _spouseName,
    communities: communities ?? _communities,
    relatives: relatives ?? _relatives,
    nextOfKin: nextOfKin ?? _nextOfKin,
    neighbours: neighbours ?? _neighbours,
    occupation: occupation ?? _occupation,
    maritalStatus: maritalStatus ?? _maritalStatus,
    privacy: privacy ?? _privacy,
    receiveCommunityUpdates: receiveCommunityUpdates ?? _receiveCommunityUpdates,
    eventReminders: eventReminders ?? _eventReminders,
    deathAnnouncements: deathAnnouncements ?? _deathAnnouncements,
    isLeader: isLeader ?? _isLeader,
    isAdmin: isAdmin ?? _isAdmin,
  );

  String? get userId => _userId;
  String? get profilePicture => _profilePicture;
  String? get fullName => _fullName;
  Address? get address => _address;
  String? get gender => _gender;
  String? get email => _email;
  String? get bio => _bio;
  String? get spouseName => _spouseName;
  List<UserCommunity>? get communities => _communities;
  List<Relationship>? get relatives => _relatives;
  List<Relationship>? get nextOfKin => _nextOfKin;
  List<Relationship>? get neighbours => _neighbours;
  String? get occupation => _occupation;
  String? get maritalStatus => _maritalStatus;
  String? get privacy => _privacy;
  bool? get receiveCommunityUpdates => _receiveCommunityUpdates;
  bool? get eventReminders => _eventReminders;
  bool? get deathAnnouncements => _deathAnnouncements;
  bool? get isLeader => _isLeader;
  bool? get isAdmin => _isAdmin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = _userId;
    map['profilePicture'] = _profilePicture;
    map['fullName'] = _fullName;
    map['bio'] = _bio;
    map['spouseName'] = _spouseName;
    if (_address != null) {
      map['address'] = _address?.toJson();
    }
    map['gender'] = _gender;
    map['email'] = _email;
    if (_communities != null) {
      map['communities'] = _communities?.map((v) => v.toJson()).toList();
    }
    if (_relatives != null) {
      map['relatives'] = _relatives?.map((v) => v.toJson()).toList();
    }
    if (_nextOfKin != null) {
      map['nextOfKin'] = _nextOfKin?.map((v) => v.toJson()).toList();
    }
    if (_neighbours != null) {
      map['neighbours'] = _neighbours?.map((v) => v.toJson()).toList();
    }
    map['occupation'] = _occupation;
    map['maritalStatus'] = _maritalStatus;
    map['privacy'] = _privacy;
    map['receiveCommunityUpdates'] = _receiveCommunityUpdates;
    map['eventReminders'] = _eventReminders;
    map['deathAnnouncements'] = _deathAnnouncements;
    map['isLeader'] = _isLeader;
    map['isAdmin'] = _isAdmin;
    return map;
  }

}

class Address {
  Address({
    String? region,
    String? district,
    String? area,
    String? houseNo,
    String? postalAddress
  }){
    _region = region;
    _district = district;
    _area = area;
    _houseNo = houseNo;
    _postalAddress = postalAddress;
  }

  Address.fromJson(dynamic json) {
    _region = json['region'];
    _district = json['district'];
    _area = json['area'];
    _houseNo = json['houseNo'];
    _postalAddress = json['postalAddress'];
  }

  String? _region;
  String? _district;
  String? _area;
  String? _houseNo;
  String? _postalAddress;

  Address copyWith({
    String? region,
    String? district,
    String? area,
    String? houseNo,
    String? postalAddress,
  }) => Address(
    region: region ?? _region,
    district: district ?? _district,
    area: area ?? _area,
    houseNo: houseNo ?? _houseNo,
    postalAddress: postalAddress ?? _postalAddress,
  );

  String? get region => _region;
  String? get district => _district;
  String? get area => _area;
  String? get houseNo => _houseNo;
  String? get postalAddress => _postalAddress;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['region'] = _region;
    map['district'] = _district;
    map['area'] = _area;
    map['houseNo'] = _houseNo;
    map['postalAddress'] = _postalAddress;
    return map;
  }

}