class PageResponse<T> {
  PageResponse({
    List<T>? content,
    Pageable? pageable,
    bool? last,
    num? totalPages,
    num? totalElements,
    bool? first,
    num? numberOfElements,
    num? size,
    num? number,
    Sort? sort,
    bool? empty
  }){
    _content = content;
    _pageable = pageable;
    _last = last;
    _totalPages = totalPages;
    _totalElements = totalElements;
    _first = first;
    _numberOfElements = numberOfElements;
    _size = size;
    _number = number;
    _sort = sort;
    _empty = empty;
  }

  PageResponse.fromJson(dynamic json, T Function(Map<String, dynamic>) fromJsonT) {
    if (json['content'] != null) {
      _content = [];
      json['content'].forEach((v) {
        _content?.add(fromJsonT(v));
      });
    }
    _pageable = json['pageable'] != null ? Pageable.fromJson(json['pageable']) : null;
    _last = json['last'];
    _totalPages = json['totalPages'];
    _totalElements = json['totalElements'];
    _first = json['first'];
    _numberOfElements = json['numberOfElements'];
    _size = json['size'];
    _number = json['number'];
    _sort = json['sort'] != null ? Sort.fromJson(json['sort']) : null;
    _empty = json['empty'];
  }

  List<dynamic>? _content;
  Pageable? _pageable;
  bool? _last;
  num? _totalPages;
  num? _totalElements;
  bool? _first;
  num? _numberOfElements;
  num? _size;
  num? _number;
  Sort? _sort;
  bool? _empty;

  PageResponse copyWith({
    List<dynamic>? content,
    Pageable? pageable,
    bool? last,
    num? totalPages,
    num? totalElements,
    bool? first,
    num? numberOfElements,
    num? size,
    num? number,
    Sort? sort,
    bool? empty,
  }) => PageResponse(  content: content ?? _content,
    pageable: pageable ?? _pageable,
    last: last ?? _last,
    totalPages: totalPages ?? _totalPages,
    totalElements: totalElements ?? _totalElements,
    first: first ?? _first,
    numberOfElements: numberOfElements ?? _numberOfElements,
    size: size ?? _size,
    number: number ?? _number,
    sort: sort ?? _sort,
    empty: empty ?? _empty,
  );

  List<dynamic>? get content => _content;
  Pageable? get pageable => _pageable;
  bool? get last => _last;
  num? get totalPages => _totalPages;
  num? get totalElements => _totalElements;
  bool? get first => _first;
  num? get numberOfElements => _numberOfElements;
  num? get size => _size;
  num? get number => _number;
  Sort? get sort => _sort;
  bool? get empty => _empty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_content != null) {
      map['content'] = _content?.map((v) => v.toJson()).toList();
    }
    if (_pageable != null) {
      map['pageable'] = _pageable?.toJson();
    }
    map['last'] = _last;
    map['totalPages'] = _totalPages;
    map['totalElements'] = _totalElements;
    map['first'] = _first;
    map['numberOfElements'] = _numberOfElements;
    map['size'] = _size;
    map['number'] = _number;
    if (_sort != null) {
      map['sort'] = _sort?.toJson();
    }
    map['empty'] = _empty;
    return map;
  }

}

class Sort {
  Sort({
      bool? unsorted, 
      bool? sorted, 
      bool? empty
  }){
    _unsorted = unsorted;
    _sorted = sorted;
    _empty = empty;
  }

  Sort.fromJson(dynamic json) {
    _unsorted = json['unsorted'];
    _sorted = json['sorted'];
    _empty = json['empty'];
  }

  bool? _unsorted;
  bool? _sorted;
  bool? _empty;

  Sort copyWith({
    bool? unsorted,
    bool? sorted,
    bool? empty,
  }) => Sort(  unsorted: unsorted ?? _unsorted,
    sorted: sorted ?? _sorted,
    empty: empty ?? _empty,
  );

  bool? get unsorted => _unsorted;
  bool? get sorted => _sorted;
  bool? get empty => _empty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['unsorted'] = _unsorted;
    map['sorted'] = _sorted;
    map['empty'] = _empty;
    return map;
  }

}

class Pageable {
  Pageable({
    Sort? sort,
    num? pageNumber,
    num? pageSize,
    num? offset,
    bool? paged,
    bool? unpaged
  }){
    _sort = sort;
    _pageNumber = pageNumber;
    _pageSize = pageSize;
    _offset = offset;
    _paged = paged;
    _unpaged = unpaged;
  }

  Pageable.fromJson(dynamic json) {
    _sort = json['sort'] != null ? Sort.fromJson(json['sort']) : null;
    _pageNumber = json['pageNumber'];
    _pageSize = json['pageSize'];
    _offset = json['offset'];
    _paged = json['paged'];
    _unpaged = json['unpaged'];
  }

  Sort? _sort;
  num? _pageNumber;
  num? _pageSize;
  num? _offset;
  bool? _paged;
  bool? _unpaged;

  Pageable copyWith({  Sort? sort,
    num? pageNumber,
    num? pageSize,
    num? offset,
    bool? paged,
    bool? unpaged,
  }) => Pageable(  sort: sort ?? _sort,
    pageNumber: pageNumber ?? _pageNumber,
    pageSize: pageSize ?? _pageSize,
    offset: offset ?? _offset,
    paged: paged ?? _paged,
    unpaged: unpaged ?? _unpaged,
  );

  Sort? get sort => _sort;
  num? get pageNumber => _pageNumber;
  num? get pageSize => _pageSize;
  num? get offset => _offset;
  bool? get paged => _paged;
  bool? get unpaged => _unpaged;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_sort != null) {
      map['sort'] = _sort?.toJson();
    }
    map['pageNumber'] = _pageNumber;
    map['pageSize'] = _pageSize;
    map['offset'] = _offset;
    map['paged'] = _paged;
    map['unpaged'] = _unpaged;
    return map;
  }
}