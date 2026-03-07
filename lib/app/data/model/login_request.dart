class LoginRequest {
  LoginRequest({
    this.username,
    this.password,
    this.verified = false,
    this.firebaseToken,
  });

  LoginRequest.fromJson(dynamic json) {
    username = json['username'];
    password = json['password'];
    verified = json['verified'];
    firebaseToken = json['firebaseToken'];
  }

  String? username;
  String? password;
  bool? verified;
  String? firebaseToken;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['username'] = username;
    map['password'] = password;
    map['verified'] = verified;
    map['firebaseToken'] = firebaseToken;

    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}