import 'user_profile.dart';

class Request {
  Request({
    String? id,
    String? title,
    String? role,
    String? description,
    String? community,
    UserProfile? user,
    String? createdBy,
    String? formattedDate
  }){
    _id = id;
    _title = title;
    _role = role;
    _description = description;
    _community = community;
    _user = user;
    _createdBy = createdBy;
    _formattedDate = formattedDate;
  }

  Request.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _role = json['role'];
    _description = json['description'];
    _community = json['community'];
    _user = json['user'] != null ? UserProfile.fromJson(json['user']) : null;
    _createdBy = json['createdBy'];
    _formattedDate = json['formattedDate'];
  }

  String? _id;
  String? _title;
  String? _role;
  String? _description;
  String? _community;
  UserProfile? _user;
  String? _createdBy;
  String? _formattedDate;

  Request copyWith({
    String? id,
    String? title,
    String? role,
    String? description,
    String? community,
    UserProfile? user,
    String? createdBy,
    String? createdOn,
  }) => Request(
    id: id ?? _id,
    title: title ?? _title,
    role: role ?? _role,
    description: description ?? _description,
    community: community ?? _community,
    user: user ?? _user,
    createdBy: createdBy ?? _createdBy,
    formattedDate: formattedDate ?? _formattedDate,
  );

  String? get id => _id;
  String? get title => _title;
  String? get role => _role;
  String? get description => _description;
  String? get community => _community;
  UserProfile? get user => _user;
  String? get createdBy => _createdBy;
  String? get formattedDate => _formattedDate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['role'] = _role;
    map['description'] = _description;
    map['community'] = _community;
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    map['createdBy'] = _createdBy;
    map['formattedDate'] = _formattedDate;
    return map;
  }

}