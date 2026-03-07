class ErrorResponse {
  ErrorResponse({
      String? path, 
      String? error, 
      String? message, 
      String? timestamp
  }){
    _path = path;
    _error = error;
    _message = message;
    _timestamp = timestamp;
  }

  ErrorResponse.fromJson(dynamic json) {
    _path = json['path'];
    _error = json['error'];
    _message = json['message'];
    _timestamp = json['timestamp'];
  }

  String? _path;
  String? _error;
  String? _message;
  String? _timestamp;

  String? get path => _path;
  String? get error => _error;
  String? get message => _message;
  String? get timestamp => _timestamp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['path'] = _path;
    map['error'] = _error;
    map['message'] = _message;
    map['timestamp'] = _timestamp;
    return map;
  }

}