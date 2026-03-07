class Location {
  Location({
    required String id,
    required String name,
    String? type,
    required double latitude,
    required double longitude,
    required String address,
    String? services,
    String? hours
  }){
    _id = id;
    _name = name;
    _type = type;
    _latitude = latitude;
    _longitude = longitude;
    _address = address;
    _services = services;
    _hours = hours;
  }

  Location.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _type = json['type'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _address = json['address'];
    _services = json['services'];
    _hours = json['hours'];
  }

  String _id = '';
  String _name = '';
  String? _type;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _address = '';
  String? _services;
  String? _hours;

  Location copyWith({
    required String id,
    required String name,
    String? type,
    required double latitude,
    required double longitude,
    required String address,
    String? services,
    String? hours,
  }) => Location(
    id: id,
    name: name,
    type: type ?? _type,
    latitude: latitude,
    longitude: longitude,
    address: address,
    services: services ?? _services,
    hours: hours ?? _hours,
  );

  String get id => _id;
  String get name => _name;
  String? get type => _type;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get address => _address;
  String? get services => _services;
  String? get hours => _hours;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['type'] = _type;
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    map['address'] = _address;
    map['services'] = _services;
    map['hours'] = _hours;
    return map;
  }

}