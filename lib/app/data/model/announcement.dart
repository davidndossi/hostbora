class Announcement {
  Announcement({
    String? id,
    String? title,
    String? description,
    String? announcementType,
    String? community,
    String? imageUrl
  }) {
    _id = id;
    _title = title;
    _description = description;
    _announcementType = announcementType;
    _community = community;
    _imageUrl = imageUrl;
  }

  Announcement.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _description = json['description'];
    _announcementType = json['announcementType'];
    _community = json['community'];
    _imageUrl = json['imageUrl'];
  }

  String? _id;
  String? _title;
  String? _description;
  String? _announcementType;
  String? _community;
  String? _imageUrl;

  Announcement copyWith({  String? id,
    String? title,
    String? description,
    String? announcementType,
    String? community,
    String? imageUrl
  }) => Announcement(  id: id ?? _id,
    title: title ?? _title,
    description: description ?? _description,
    announcementType: announcementType ?? _announcementType,
    community: community ?? _community,
    imageUrl: imageUrl ?? _imageUrl,
  );

  String? get id => _id;
  String? get title => _title;
  String? get description => _description;
  String? get announcementType => _announcementType;
  String? get community => _community;
  String? get imageUrl => _imageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['description'] = _description;
    map['announcementType'] = _announcementType;
    map['community'] = _community;
    map['imageUrl'] = _imageUrl;
    return map;
  }

}