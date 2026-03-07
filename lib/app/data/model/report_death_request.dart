import 'dart:io';

class ReportDeathRequest {
  ReportDeathRequest({
    String? name,
    String? description,
    String? relation,
    File? deathCertificate,
    File? picture,
    String? communityId,
    String? userId
  }){
    _name = name;
    _description = description;
    _relation = relation;
    _deathCertificate = deathCertificate;
    _picture = picture;
    _communityId = communityId;
    _userId = userId;
  }

  ReportDeathRequest.fromJson(dynamic json) {
    _name = json['name'];
    _description = json['description'];
    _relation = json['relation'];
    _communityId = json['communityId'];
    _userId = json['userId'];
  }

  String? _name;
  String? _description;
  String? _relation;
  File? _deathCertificate;
  File? _picture;
  String? _communityId;
  String? _userId;

  ReportDeathRequest copyWith({
    String? name,
    String? description,
    String? relation,
    File? deathCertificate,
    File? picture,
    String? communityId,
    String? userId,
  }) => ReportDeathRequest(
    name: name ?? _name,
    description: description ?? _description,
    relation: relation ?? _relation,
    deathCertificate: deathCertificate ?? _deathCertificate,
    picture: picture ?? _picture,
    communityId: communityId ?? _communityId,
    userId: userId ?? _userId,
  );

  String? get name => _name;
  String? get description => _description;
  String? get relation => _relation;
  File? get deathCertificate => _deathCertificate;
  File? get picture => _picture;
  String? get communityId => _communityId;
  String? get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['description'] = _description;
    map['relation'] = _relation;
    map['community_id'] = _communityId;
    map['user_id'] = _userId;
    return map;
  }

}