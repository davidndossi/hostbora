class UserProfileSaveRequest {
  UserProfileSaveRequest({
    String? jsonString,
    String? userId
  }) {
    _jsonString = jsonString;
    _userId = userId;
  }

  UserProfileSaveRequest.fromJson(dynamic json) {
    _jsonString = json['json'];
    _userId = json['userId'];
  }

  String? _jsonString;
  String? _userId;

  UserProfileSaveRequest copyWith({
    String? communityId,
    String? userId,
  }) => UserProfileSaveRequest(
    jsonString: communityId ?? _jsonString,
    userId: userId ?? _userId,
  );

  String? get jsonString => _jsonString;
  String? get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['json'] = _jsonString;
    map['userId'] = _userId;
    return map;
  }
}