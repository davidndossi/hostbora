class InviteRequest {
  InviteRequest({
    String? leaderId,
    String? role
  }){
    _leaderId = leaderId;
    _role = role;
  }

  InviteRequest.fromJson(dynamic json) {
    _leaderId = json['leaderId'];
    _role = json['role'];
  }

  String? _leaderId;
  String? _role;

  InviteRequest copyWith({
    String? leaderId,
    String? role,
  }) => InviteRequest(
    leaderId: leaderId ?? _leaderId,
    role: role ?? _role,
  );

  String? get leaderId => _leaderId;
  String? get role => _role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['leaderId'] = _leaderId;
    map['role'] = _role;
    return map;
  }

}