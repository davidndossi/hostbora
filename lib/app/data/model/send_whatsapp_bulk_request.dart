class SendWhatsAppBulkRequest {
  SendWhatsAppBulkRequest({
    required List<String> phoneNumbers,
    String? message,
  }) {
    _phoneNumbers = phoneNumbers;
    _message = message;
  }

  List<String>? _phoneNumbers;
  String? _message;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phoneNumbers': _phoneNumbers,
      'message': _message,
    };
  }
}
