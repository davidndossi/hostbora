class Notification {
  Notification({
    String? id,
    String? initiator,
    String? recipient,
    String? type,
    bool? delivered,
    String? msg,
    String? title,
    String? subtitle
  }){
    _id = id;
    _initiator = initiator;
    _recipient = recipient;
    _type = type;
    _delivered = delivered;
    _msg = msg;
    _title = title;
    _subtitle = subtitle;
  }

  Notification.fromJson(dynamic json) {
    _id = json['id'];
    _initiator = json['initiator'];
    _recipient = json['recipient'];
    _type = json['type'];
    _delivered = json['delivered'];
    _msg = json['msg'];
    _title = json['title'];
    _subtitle = json['subtitle'];
  }

  String? _id;
  String? _initiator;
  String? _recipient;
  String? _type;
  bool? _delivered;
  String? _msg;
  String? _title;
  String? _subtitle;

  Notification copyWith({
    String? id,
    String? initiator,
    String? recipient,
    String? type,
    bool? delivered,
    String? msg,
    String? title,
    String? subtitle,
  }) => Notification(
    id: id ?? _id,
    initiator: initiator ?? _initiator,
    recipient: recipient ?? _recipient,
    type: type ?? _type,
    delivered: delivered ?? _delivered,
    msg: msg ?? _msg,
    title: title ?? _title,
    subtitle: subtitle ?? _subtitle,
  );

  String? get id => _id;
  String? get initiator => _initiator;
  String? get recipient => _recipient;
  String? get type => _type;
  bool? get delivered => _delivered;
  String? get msg => _msg;
  String? get title => _title;
  String? get subtitle => _subtitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['initiator'] = _initiator;
    map['recipient'] = _recipient;
    map['type'] = _type;
    map['delivered'] = _delivered;
    map['msg'] = _msg;
    map['title'] = _title;
    map['subtitle'] = _subtitle;
    return map;
  }

}