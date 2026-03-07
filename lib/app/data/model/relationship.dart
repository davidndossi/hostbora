class Relationship {
  Relationship({
    String? id,
    String? type,
    String? lifeStatus,
    String? fullName,
    String? age,
  }){
    _id = id;
    _type = type;
    _lifeStatus = lifeStatus;
    _fullName = fullName;
    _age = age;
  }

  Relationship.fromJson(dynamic json) {
    _id = json['id'];
    _type = json['type'];
    _lifeStatus = json['lifeStatus'];
    _fullName = json['fullName'];
    _age = json['age'];
  }

  String? _id;
  String? _type;
  String? _lifeStatus;
  String? _fullName;
  String? _age;

  Relationship copyWith({  String? id,
    String? type,
    String? lifeStatus,
    String? fullName,
    String? age,
  }) => Relationship(  id: id ?? _id,
    type: type ?? _type,
    lifeStatus: lifeStatus ?? _lifeStatus,
    fullName: fullName ?? _fullName,
    age: age ?? _age,
  );

  String? get id => _id;
  String? get type => _type;
  String? get lifeStatus => _lifeStatus;
  String? get fullName => _fullName;
  String? get age => _age;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['type'] = _type;
    map['lifeStatus'] = _lifeStatus;
    map['fullName'] = _fullName;
    map['age'] = _age;
    return map;
  }

}