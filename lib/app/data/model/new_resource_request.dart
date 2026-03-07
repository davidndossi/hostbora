import 'dart:io';

class NewResourceRequest {
  NewResourceRequest({
    String? title,
    String? description,
    String? category,
    String? type,
    required File file,
    String? communityId,
    String? userId
  }){
    _title = title;
    _description = description;
    _category = category;
    _type = type;
    _file = file;
    _communityId = communityId;
    _userId = userId;
  }

  NewResourceRequest.fromJson(dynamic json) {
    _title = json['title'];
    _description = json['description'];
    _category = json['category'];
    _type = json['type'];
    _communityId = json['community_id'];
    _userId = json['user_id'];
  }

  String? _title;
  String? _description;
  String? _category;
  String? _type;
  late File _file;
  String? _communityId;
  String? _userId;

  NewResourceRequest copyWith({
    String? title,
    String? description,
    String? category,
    String? type,
    File? file,
    String? communityId,
    String? userId,
  }) => NewResourceRequest(
    title: title ?? _title,
    description: description ?? _description,
    category: category ?? _category,
    type: type ?? _type,
    file: file ?? _file,
    communityId: communityId ?? _communityId,
    userId: userId ?? _userId,
  );

  String? get title => _title;
  String? get description => _description;
  String? get category => _category;
  String? get type => _type;
  File get file => _file;
  String? get communityId => _communityId;
  String? get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = _title;
    map['description'] = _description;
    map['category'] = _category;
    map['type'] = _type;
    map['community_id'] = _communityId;
    map['user_id'] = _userId;
    return map;
  }

}