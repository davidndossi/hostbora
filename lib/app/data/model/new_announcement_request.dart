class NewAnnouncementRequest {
  NewAnnouncementRequest({
      String? title, 
      String? description, 
      String? type, 
      String? communityId, 
      String? userId
  }){
    _title = title;
    _description = description;
    _type = type;
    _communityId = communityId;
    _userId = userId;
  }

  NewAnnouncementRequest.fromJson(dynamic json) {
    _title = json['title'];
    _description = json['description'];
    _type = json['type'];
    _communityId = json['community_id'];
    _userId = json['user_id'];
  }

  String? _title;
  String? _description;
  String? _type;
  String? _communityId;
  String? _userId;

  NewAnnouncementRequest copyWith({  String? title,
    String? description,
    String? type,
    String? communityId,
    String? userId,
  }) => NewAnnouncementRequest(
    title: title ?? _title,
    description: description ?? _description,
    type: type ?? _type,
    communityId: communityId ?? _communityId,
    userId: userId ?? _userId,
  );

  String? get title => _title;
  String? get description => _description;
  String? get type => _type;
  String? get communityId => _communityId;
  String? get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = _title;
    map['description'] = _description;
    map['type'] = _type;
    map['community_id'] = _communityId;
    map['user_id'] = _userId;
    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }

}