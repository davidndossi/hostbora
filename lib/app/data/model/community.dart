class Community {
  Community({
    String? id,
    String? name,
    String? description,
    String? acceptance,
    String? category,
    String? status,
    num? postsCount,
    String? location,
    bool? isInviteOnly,
    bool? isPrivate,
    String? tags,
    String? dp,
    String? createdAt
  }){
    _id = id;
    _name = name;
    _description = description;
    _acceptance = acceptance;
    _category = category;
    _status = status;
    _postsCount = postsCount;
    _location = location;
    _isInviteOnly = isInviteOnly;
    _isPrivate = isPrivate;
    _tags = tags;
    _dp = dp;
    _createdAt = createdAt;
  }

  Community.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _description = json['description'];
    _acceptance = json['acceptance'];
    _category = json['category'];
    _status = json['status'];
    _postsCount = json['postsCount'];
    _location = json['location'];
    _isInviteOnly = json['inviteOnly'];
    _isPrivate = json['isPrivate'];
    _tags = json['tags'];
    _dp = json['dp'];
    _createdAt = json['createdAt'];
  }

  String? _id;
  String? _name;
  String? _description;
  String? _acceptance;
  String? _category;
  String? _status;
  num? _postsCount;
  String? _location;
  bool? _isInviteOnly;
  bool? _isPrivate;
  String? _tags;
  String? _dp;
  String? _createdAt;

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? acceptance,
    String? category,
    String? status,
    num? postsCount,
    String? location,
    bool? isInviteOnly,
    bool? isPrivate,
    String? tags,
    String? dp,
    String? createdAt
  }) => Community(
    id: id ?? _id,
    name: name ?? _name,
    description: description ?? _description,
    acceptance: acceptance ?? _acceptance,
    category: category ?? _category,
    status: status ?? _status,
    postsCount: postsCount ?? _postsCount,
    location: location ?? _location,
    isInviteOnly: isInviteOnly ?? _isInviteOnly,
    isPrivate: isPrivate ?? _isPrivate,
    tags: tags ?? _tags,
    dp: dp ?? _dp,
    createdAt: createdAt ?? _createdAt,
  );

  String? get id => _id;
  String? get name => _name;
  String? get description => _description;
  String? get acceptance => _acceptance;
  String? get category => _category;
  String? get status => _status;
  num? get postsCount => _postsCount;
  String? get location => _location;
  bool? get isInviteOnly => _isInviteOnly;
  bool? get isPrivate => _isPrivate;
  String? get tags => _tags;
  String? get dp => _dp;
  String? get createdAt => _createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['acceptance'] = _acceptance;
    map['category'] = _category;
    map['status'] = _status;
    map['postsCount'] = _postsCount;
    map['location'] = _location;
    map['inviteOnly'] = _isInviteOnly;
    map['isPrivate'] = _isPrivate;
    map['tags'] = _tags;
    map['dp'] = _dp;
    map['createdAt'] = _createdAt;
    return map;
  }

}