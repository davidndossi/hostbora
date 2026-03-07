class NewEventRequest {
  NewEventRequest({
    String? name,
    String? description,
    String? eventDt,
    String? startTime,
    String? endTime,
    String? location,
    String? cost,
    String? eventVisibility,
    String? communityId,
    String? userId
  }){
    _name = name;
    _description = description;
    _eventDt = eventDt;
    _startTime = startTime;
    _endTime = endTime;
    _location = location;
    _cost = cost;
    _eventVisibility = eventVisibility;
    _communityId = communityId;
    _userId = userId;
  }

  NewEventRequest.fromJson(dynamic json) {
    _name = json['name'];
    _description = json['description'];
    _eventDt = json['eventDt'];
    _startTime = json['startTime'];
    _endTime = json['endTime'];
    _location = json['location'];
    _cost = json['cost'];
    _eventVisibility = json['eventVisibility'];
    _communityId = json['communityId'];
    _userId = json['userId'];
  }

  String? _name;
  String? _description;
  String? _eventDt;
  String? _startTime;
  String? _endTime;
  String? _location;
  String? _cost;
  String? _eventVisibility;
  String? _communityId;
  String? _userId;

  NewEventRequest copyWith({
    String? name,
    String? description,
    String? eventDt,
    String? startTime,
    String? endTime,
    String? location,
    String? cost,
    String? eventVisibility,
    String? communityId,
    String? userId,
  }) => NewEventRequest(
    name: name ?? _name,
    description: description ?? _description,
    eventDt: eventDt ?? _eventDt,
    startTime: startTime ?? _startTime,
    endTime: endTime ?? _endTime,
    location: location ?? _location,
    cost: cost ?? _cost,
    eventVisibility: eventVisibility ?? _eventVisibility,
    communityId: communityId ?? _communityId,
    userId: userId ?? _userId,
  );

  String? get name => _name;
  String? get description => _description;
  String? get eventDt => _eventDt;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  String? get location => _location;
  String? get cost => _cost;
  String? get eventVisibility => _eventVisibility;
  String? get communityId => _communityId;
  String? get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['description'] = _description;
    map['eventDt'] = _eventDt;
    map['startTime'] = _startTime;
    map['endTime'] = _endTime;
    map['location'] = _location;
    map['cost'] = _cost;
    map['eventVisibility'] = _eventVisibility;
    map['communityId'] = _communityId;
    map['userId'] = _userId;
    return map;
  }

}