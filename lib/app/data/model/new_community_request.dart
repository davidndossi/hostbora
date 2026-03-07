class NewCommunityRequest {
  NewCommunityRequest({
    String? name,
    String? description,
    String? dp,
    String? category,
    String? location,
    String? tags,
    String? chairmanId,
    String? chairmanName,
    String? visibility,
    String? communityId
  }){
    _name = name;
    _description = description;
    _dp = dp;
    _category = category;
    _location = location;
    _tags = tags;
    _chairmanId = chairmanId;
    _chairmanName = chairmanName;
    _visibility = visibility;
    _communityId = communityId;
  }

  NewCommunityRequest.fromJson(dynamic json) {
    _name = json['name'];
    _description = json['description'];
    _dp = json['dp'];
    _category = json['category'];
    _location = json['location'];
    _tags = json['tags'];
    _chairmanId = json['chairmanId'];
    _chairmanName = json['chairmanName'];
    _visibility = json['visibility'];
    _communityId = json['communityId'];
  }

  String? _name;
  String? _description;
  String? _dp;
  String? _category;
  String? _location;
  String? _tags;
  String? _chairmanId;
  String? _chairmanName;
  String? _visibility;
  String? _communityId;

  NewCommunityRequest copyWith({
    String? name,
    String? description,
    String? dp,
    String? category,
    String? location,
    String? tags,
    String? chairmanId,
    String? chairmanName,
    String? visibility,
    String? communityId,
  }) => NewCommunityRequest(
    name: name ?? _name,
    description: description ?? _description,
    dp: dp ?? _dp,
    category: category ?? _category,
    location: location ?? _location,
    tags: tags ?? _tags,
    chairmanId: chairmanId ?? _chairmanId,
    chairmanName: chairmanName ?? _chairmanName,
    visibility: visibility ?? _visibility,
    communityId: communityId ?? _communityId,
  );

  String? get name => _name;
  String? get description => _description;
  String? get dp => _dp;
  String? get category => _category;
  String? get location => _location;
  String? get tags => _tags;
  String? get chairmanId => _chairmanId;
  String? get chairmanName => _chairmanName;
  String? get visibility => _visibility;
  String? get communityId => _communityId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['description'] = _description;
    map['dp'] = _dp;
    map['category'] = _category;
    map['location'] = _location;
    map['tags'] = _tags;
    map['chairmanId'] = _chairmanId;
    map['chairmanName'] = _chairmanName;
    map['visibility'] = _visibility;
    map['communityId'] = _communityId;
    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }

}