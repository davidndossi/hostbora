class Post {
  Post({
      String? id, 
      String? title, 
      String? description, 
      String? createdBy, 
      String? community, 
      String? createdOn, 
      String? imageUrl
  }) {
    _id = id;
    _title = title;
    _description = description;
    _createdBy = createdBy;
    _community = community;
    _createdOn = createdOn;
    _imageUrl = imageUrl;
  }

  Post.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _description = json['description'];
    _createdBy = json['createdBy'];
    _community = json['community'];
    _createdOn = json['createdOn'];
    _imageUrl = json['imageUrl'];
  }

  String? _id;
  String? _title;
  String? _description;
  String? _createdBy;
  String? _community;
  String? _createdOn;
  String? _imageUrl;

  Post copyWith({  String? id,
    String? title,
    String? description,
    String? createdBy,
    String? community,
    String? createdOn,
    String? imageUrl,
  }) => Post(  id: id ?? _id,
    title: title ?? _title,
    description: description ?? _description,
    createdBy: createdBy ?? _createdBy,
    community: community ?? _community,
    createdOn: createdOn ?? _createdOn,
    imageUrl: imageUrl ?? _imageUrl,
  );

  String? get id => _id;
  String? get title => _title;
  String? get description => _description;
  String? get createdBy => _createdBy;
  String? get community => _community;
  String? get createdOn => _createdOn;
  String? get imageUrl => _imageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['description'] = _description;
    map['createdBy'] = _createdBy;
    map['community'] = _community;
    map['createdOn'] = _createdOn;
    map['imageUrl'] = _imageUrl;
    return map;
  }

}