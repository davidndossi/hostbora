class Event {
  Event({
    String? id,
    String? name,
    String? description,
    String? eventVisibility,
    String? community,
    String? date,
    String? startTime,
    String? endTime,
    String? location,
    String? cost,
    String? imageUrl
  }) {
    _id = id;
    _name = name;
    _description = description;
    _eventVisibility = eventVisibility;
    _community = community;
    _date = date;
    _startTime = startTime;
    _endTime = endTime;
    _location = location;
    _cost = cost;
  }

  Event.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _description = json['description'];
    _eventVisibility = json['eventVisibility'];
    _community = json['community'];
    _date = json['date'];
    _startTime = json['startTime'];
    _endTime = json['endTime'];
    _location = json['location'];
    _cost = json['cost'];
  }

  String? _id;
  String? _name;
  String? _description;
  String? _eventVisibility;
  String? _community;
  String? _date;
  String? _startTime;
  String? _endTime;
  String? _location;
  String? _cost;
  String? _imageUrl;

  Event copyWith({
    String? id,
    String? name,
    String? description,
    String? eventVisibility,
    String? community,
    String? date,
    String? startTime,
    String? endTime,
    String? location,
    String? cost,
    String? imageUrl
  }) => Event(  id: id ?? _id,
    name: name ?? _name,
    description: description ?? _description,
    eventVisibility: eventVisibility ?? _eventVisibility,
    community: community ?? _community,
    date: date ?? _date,
    startTime: startTime ?? _startTime,
    endTime: endTime ?? _endTime,
    location: location ?? _location,
    cost: cost ?? _cost,
    imageUrl: imageUrl ?? _imageUrl
  );

  String? get id => _id;
  String? get name => _name;
  String? get description => _description;
  String? get eventVisibility => _eventVisibility;
  String? get community => _community;
  String? get date => _date;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  String? get location => _location;
  String? get cost => _cost;
  String? get imageUrl => _imageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['eventVisibility'] = _eventVisibility;
    map['community'] = _community;
    map['date'] = _date;
    map['startTime'] = _startTime;
    map['endTime'] = _endTime;
    map['location'] = _location;
    map['cost'] = _cost;
    map['imageUrl'] = _imageUrl;
    return map;
  }

}