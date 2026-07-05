class GeneralResponse {
  GeneralResponse({
    this.responseCode,
    this.message,
    this.data
  });

  GeneralResponse.fromJson(dynamic json) {
    responseCode = json['responseCode']?.toString();
    message = json['message']?.toString();
    data = json['data'];
  }

  String? responseCode;
  String? message;
  dynamic data;

  bool get isSuccess {
    final code = responseCode;
    return code == '0' || code == '200' || code == '201';
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['responseCode'] = responseCode;
    map['message'] = message;
    map['data'] = data;

    return map;
  }

}