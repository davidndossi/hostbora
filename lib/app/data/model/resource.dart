class Resource {
  Resource({
    String? id,
    String? title,
    String? description,
    String? filePath,
    String? type,
    String? category,
    String? community,
    bool? isApproved,
    required bool isFeatured,
  }){
    _id = id;
    _title = title;
    _description = description;
    _filePath = filePath;
    _type = type;
    _category = category;
    _community = community;
    _isApproved = isApproved;
    _isFeatured = isFeatured;
  }

  Resource.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _description = json['description'];
    _filePath = json['filePath'];
    _type = json['type'];
    _category = json['category'];
    _community = json['community'];
    _isApproved = json['isApproved'];
    _isFeatured = json['isFeatured'];
  }

  String? _id;
  String? _title;
  String? _description;
  String? _filePath;
  String? _type;
  String? _category;
  String? _community;
  bool? _isApproved;
  bool _isFeatured = false;
  late String? icon;

  Resource copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    String? type,
    String? category,
    String? community,
    bool? isApproved,
    required bool isFeatured
  }) => Resource(
    id: id ?? _id,
    title: title ?? _title,
    description: description ?? _description,
    filePath: filePath ?? _filePath,
    type: type ?? _type,
    category: category ?? _category,
    community: community ?? _community,
    isApproved: isApproved ?? _isApproved,
    isFeatured: isFeatured,
  );

  String? get id => _id;
  String? get title => _title;
  String? get description => _description;
  String? get filePath => _filePath;
  String? get type => _type;
  String? get category => _category;
  String? get community => _community;
  bool? get isApproved => _isApproved;
  bool get isFeatured => _isFeatured;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['description'] = _description;
    map['filePath'] = _filePath;
    map['type'] = _type;
    map['category'] = _category;
    map['community'] = _community;
    map['isApproved'] = _isApproved;
    map['isFeatured'] = _isFeatured;
    return map;
  }

}