class GeneralResponse {
  GeneralResponse({
    this.responseCode,
    this.message,
    this.data
  });

  GeneralResponse.fromJson(dynamic json) {
    responseCode = json['responseCode'];
    message = json['message'];
    data = json['data'];
  }

  String? responseCode;
  String? message;
  dynamic data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['responseCode'] = responseCode;
    map['message'] = message;
    map['data'] = data;

    return map;
  }

}