class LoginResponse {
  LoginResponse({
    String? responseCode,
    String? reference,
    String? message,
    String? status,
    String? token,
    int? expiresIn,
    String? refreshToken,
    int? refreshExpiresIn,
    User? user,
    int? build,
    int? release,
    bool? staffRestricted,
    List<String>? staffPermissions,
    Map<String, dynamic>? propertyScope,
  }){
    _message = message;
    _status = status;
    _token = token;
    _expiresIn = expiresIn;
    _refreshToken = refreshToken;
    _refreshExpiresIn = refreshExpiresIn;
    _user = user;
    _build = build;
    _release = release;
    _staffRestricted = staffRestricted;
    _staffPermissions = staffPermissions;
    _propertyScope = propertyScope;
  }

  LoginResponse.fromJson(dynamic json) {
    _message = json['message'];
    _status = json['status'];
    _token = json['token'];
    _expiresIn = json['expires_in'];
    _refreshToken = json['refresh_token'];
    _refreshExpiresIn = json['refresh_expires_in'];
    _user = json['user'] != null ? User.fromJson(json['user']) : null;
    _build = json['build'];
    _release = json['release'];
    _staffRestricted = json['staffRestricted'] == true;
    final rawPerms = json['staffPermissions'];
    if (rawPerms is List) {
      _staffPermissions = rawPerms.map((e) => e.toString()).toList();
    }
    final scope = json['propertyScope'];
    if (scope is Map) {
      _propertyScope = Map<String, dynamic>.from(scope);
    }
    _hasStaffFlag = json is Map && json.containsKey('staffRestricted');
  }

  String? _message;
  String? _status;
  String? _token;
  int? _expiresIn;
  String? _refreshToken;
  int? _refreshExpiresIn;
  User? _user;
  int? _build;
  int? _release;
  bool? _staffRestricted;
  List<String>? _staffPermissions;
  Map<String, dynamic>? _propertyScope;
  bool _hasStaffFlag = false;

  String? get message => _message;
  String? get status => _status;
  String? get token => _token;
  int? get expiresIn => _expiresIn;
  String? get refreshToken => _refreshToken;
  int? get refreshExpiresIn => _refreshExpiresIn;
  User? get user => _user;
  int? get build => _build;
  int? get release => _release;
  bool get hasStaffFlag => _hasStaffFlag;
  bool? get staffRestricted => _staffRestricted;
  List<String>? get staffPermissions => _staffPermissions;
  Map<String, dynamic>? get propertyScope => _propertyScope;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    map['status'] = _status;
    map['token'] = _token;
    map['expires_in'] = _expiresIn;
    map['refresh_token'] = _refreshToken;
    map['refresh_expires_in'] = _refreshExpiresIn;
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    map['build'] = _build;
    map['release'] = _release;
    return map;
  }

}

class User {
  User({
    String? id,
    String? msisdn,
    String? address,
    String? fullName,
    List<dynamic>? contacts,
    String? email,
    String? nidaNumber,
    List<String>? roles,
    List<dynamic>? communities,
    required bool isLeader,
    required bool isAdmin
  }){
    _id = id;
    _msisdn = msisdn;
    _address = address;
    _fullName = fullName;
    _contacts = contacts;
    _email = email;
    _nidaNumber = nidaNumber;
    _roles = roles;
    _communities = communities;
    _isLeader = isLeader;
    _isAdmin = isAdmin;
  }

  User.fromJson(dynamic json) {
    _id = json['id'];
    _msisdn = json['msisdn'];
    _address = json['address'];
    _fullName = json['fullName'];
    if (json['contacts'] != null) {
      _contacts = [];
      json['contacts'].forEach((v) {
        _contacts?.add(v);
      });
    }
    _email = json['email'];
    _nidaNumber = json['nidaNumber'];
    _roles = List<String>.from(json['roles']);
    if (json['communities'] != null) {
      _communities = [];
      json['communities'].forEach((v) {
        _communities?.add(v);
      });
    }
    _isLeader = json['isLeader'];
    _isAdmin = json['isAdmin'];
  }

  String? _id;
  String? _msisdn;
  String? _address;
  String? _fullName;
  List<dynamic>? _contacts;
  String? _email;
  String? _nidaNumber;
  List<String>? _roles;
  List<dynamic>? _communities;
  bool _isLeader = false;
  bool _isAdmin = false;

  String? get id => _id;
  String? get msisdn => _msisdn;
  String? get address => _address;
  String? get fullName => _fullName;
  List<dynamic>? get contacts => _contacts;
  String? get email => _email;
  String? get nidaNumber => _nidaNumber;
  List<String>? get roles => _roles;
  List<dynamic>? get communities => _communities;
  bool get isLeader => _isLeader;
  bool get isAdmin => _isAdmin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['msisdn'] = _msisdn;
    map['address'] = _address;
    map['fullName'] = _fullName;
    if (_contacts != null) {
      map['contacts'] = _contacts;
    }
    map['email'] = _email;
    map['nidaNumber'] = _nidaNumber;
    map['isLeader'] = _isLeader;
    map['isAdmin'] = _isAdmin;
    if (_roles != null) {
      map['roles'] = _roles?.map((v) => v.toString()).toList();
    }
    if (_communities != null) {
      map['communities'] = _communities?.map((v) => v.toString()).toList();
    }
    return map;
  }
}