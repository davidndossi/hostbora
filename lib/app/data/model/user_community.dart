class UserCommunity {
  UserCommunity({
    String? id,
    String? name,
    String? status,
    String? role,
    String? joinedAt,
    String? updatedAt
  }){
    _id = id;
    _name = name;
    _status = status;
    _role = role;
    _joinedAt = joinedAt;
    _updatedAt = updatedAt;
  }

  UserCommunity.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _status = json['status'];
    _role = json['role'];
    _joinedAt = json['joinedAt'];
    _updatedAt = json['updatedAt'];
  }

  String? _id;
  String? _name;
  String? _status;
  String? _role;
  String? _joinedAt;
  String? _updatedAt;

  UserCommunity copyWith({
    String? id,
    String? name,
    String? status,
    String? role,
    String? joinedAt,
    String? updatedAt,
  }) => UserCommunity(
    id: id ?? _id,
    name: name ?? _name,
    status: status ?? _status,
    role: role ?? _role,
    joinedAt: joinedAt ?? _joinedAt,
    updatedAt: updatedAt ?? _updatedAt,
  );

  String? get id => _id;
  String? get name => _name;
  String? get status => _status;
  String? get role => _role;
  String? get joinedAt => _joinedAt;
  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['status'] = _status;
    map['role'] = _role;
    map['joinedAt'] = _joinedAt;
    map['updatedAt'] = _updatedAt;
    return map;
  }

}