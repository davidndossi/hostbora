class BodyRequest {
  BodyRequest({
    this.transactionDate,
    this.data
  });

  BodyRequest.fromJson(dynamic json) {
    transactionDate = json['encAesKey'];
    data = json['payload'];
  }

  String? transactionDate;
  String? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['encAesKey'] = transactionDate;
    map['payload'] = data;

    return map;
  }

  @override
  String toString() {
    return toJson().toString();
  }

}