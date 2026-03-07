class Attachment {
  Attachment({String? fileContent, String? fileSize, String? fileType, String? fileName}){
    _fileContent = fileContent;
    _fileSize = fileSize;
    _fileType = fileType;
    _fileName = fileName;
  }

  Attachment.fromJson(dynamic json) {
    _fileContent = json['fileContent'];
    _fileSize = json['fileSize'];
    _fileType = json['fileType'];
    _fileName = json['fileName'];
  }

  String? _fileContent;
  String? _fileSize;
  String? _fileType;
  String? _fileName;

  String? get fileContent => _fileContent;
  String? get fileSize => _fileSize;
  String? get fileType => _fileType;
  String? get fileName => _fileName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['fileContent'] = _fileContent;
    map['fileSize'] = _fileSize;
    map['fileType'] = _fileType;
    map['fileName'] = _fileName;
    return map;
  }
}