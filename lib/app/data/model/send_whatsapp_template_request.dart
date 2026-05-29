class SendWhatsAppTemplateRequest {
  SendWhatsAppTemplateRequest({
    String? phoneNumber,
    required String templateName,
    required String languageCode,
    List<String>? bodyParameters,
    List<String>? headerParameters,
  })  : _phoneNumber = phoneNumber,
        _templateName = templateName,
        _languageCode = languageCode,
        _bodyParameters = bodyParameters ?? const [],
        _headerParameters = headerParameters ?? const [];

  final String? _phoneNumber;
  final String _templateName;
  final String _languageCode;
  final List<String> _bodyParameters;
  final List<String> _headerParameters;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (_phoneNumber != null && _phoneNumber!.trim().isNotEmpty)
        'phoneNumber': _phoneNumber,
      'templateName': _templateName,
      'languageCode': _languageCode,
      'bodyParameters': _bodyParameters,
      if (_headerParameters.isNotEmpty) 'headerParameters': _headerParameters,
    };
  }
}

class SendWhatsAppTemplateBulkRequest {
  SendWhatsAppTemplateBulkRequest({
    required List<String> phoneNumbers,
    required String templateName,
    required String languageCode,
    List<String>? bodyParameters,
    List<String>? headerParameters,
  })  : _phoneNumbers = phoneNumbers,
        _templateName = templateName,
        _languageCode = languageCode,
        _bodyParameters = bodyParameters ?? const [],
        _headerParameters = headerParameters ?? const [];

  final List<String> _phoneNumbers;
  final String _templateName;
  final String _languageCode;
  final List<String> _bodyParameters;
  final List<String> _headerParameters;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phoneNumbers': _phoneNumbers,
      'templateName': _templateName,
      'languageCode': _languageCode,
      'bodyParameters': _bodyParameters,
      if (_headerParameters.isNotEmpty) 'headerParameters': _headerParameters,
    };
  }
}
