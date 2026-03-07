class SearchRequest {
  SearchRequest({
      String? searchBy, 
      String? searchValue
  }){
    _searchBy = searchBy;
    _searchValue = searchValue;
  }

  SearchRequest.fromJson(dynamic json) {
    _searchBy = json['searchBy'];
    _searchValue = json['searchValue'];
  }

  String? _searchBy;
  String? _searchValue;

  String? get searchBy => _searchBy;
  String? get searchValue => _searchValue;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['searchBy'] = _searchBy;
    map['searchValue'] = _searchValue;
    return map;
  }

}