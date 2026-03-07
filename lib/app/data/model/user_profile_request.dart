class UserProfileRequest {
  UserProfileRequest({
    String? communityId,
    String? userId,
    String? leaderId
  }){
    _communityId = communityId;
    _userId = userId;
    _leaderId = leaderId;
  }

  UserProfileRequest.fromJson(dynamic json) {
    _communityId = json['communityId'];
    _userId = json['userId'];
    _leaderId = json['_leaderId'];
  }

  String? _communityId;
  String? _userId;
  String? _leaderId;

  UserProfileRequest copyWith({
    String? communityId,
    String? userId,
    String? leaderId
  }) => UserProfileRequest(
    communityId: communityId ?? _communityId,
    userId: userId ?? _userId,
    leaderId: leaderId ?? _leaderId,
  );

  String? get communityId => _communityId;
  String? get userId => _userId;
  String? get leaderId => _leaderId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['communityId'] = _communityId;
    map['userId'] = _userId;
    map['leaderId'] = _leaderId;
    return map;
  }

}