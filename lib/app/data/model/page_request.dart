class PageRequest {
  PageRequest({
    num? page,
    num? size
  }){
    _page = page;
    _size = size;
  }

  PageRequest.fromJson(dynamic json) {
    _page = json['page'];
    _size = json['size'];
  }

  num? _page;
  num? _size;

  PageRequest copyWith({
    num? page,
    num? size,
  }) => PageRequest(
    page: page ?? _page,
    size: size ?? _size,
  );

  num? get page => _page;
  num? get size => _size;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['page'] = _page;
    map['size'] = _size;
    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }

}