/// Request body for POST /api/snippe/sessions/send-whatsapp
class SendPaymentLinkRequest {
  SendPaymentLinkRequest({
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    this.description,
    this.bookingId,
    this.tenantId,
    this.message,
    this.expiresIn = 3600,
  });

  /// Amount in TZS (integer, minimum 500).
  final int amount;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? description;
  final String? bookingId;
  final String? tenantId;
  final String? message;
  final int expiresIn;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (bookingId != null && bookingId!.isNotEmpty) 'bookingId': bookingId,
      if (tenantId != null && tenantId!.isNotEmpty) 'tenantId': tenantId,
      if (message != null && message!.isNotEmpty) 'message': message,
      'expiresIn': expiresIn,
    };
  }
}

/// Snippe checkout session returned by the backend.
class SnippePaymentSession {
  const SnippePaymentSession({
    required this.id,
    required this.snippeReference,
    required this.amount,
    required this.status,
    required this.paymentLinkUrl,
    required this.paymentUrl,
    this.bookingId,
    this.tenantId,
  });

  final String id;
  final String snippeReference;
  final int amount;
  final String status;
  final String paymentLinkUrl;
  final String paymentUrl;
  final String? bookingId;
  final String? tenantId;

  factory SnippePaymentSession.fromJson(Map<String, dynamic> json) {
    return SnippePaymentSession(
      id: (json['id'] as String?) ?? '',
      snippeReference: (json['snippeReference'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      paymentLinkUrl: (json['paymentLinkUrl'] as String?) ?? '',
      paymentUrl: (json['paymentUrl'] as String?) ?? '',
      bookingId: json['bookingId'] as String?,
      tenantId: json['tenantId'] as String?,
    );
  }
}

class SendPaymentLinkResult {
  const SendPaymentLinkResult({
    required this.payment,
    required this.whatsappSuccess,
    this.whatsappError,
    this.whatsappMessageId,
  });

  final SnippePaymentSession payment;
  final bool whatsappSuccess;
  final String? whatsappError;
  final String? whatsappMessageId;

  factory SendPaymentLinkResult.fromResponseData(Map<String, dynamic>? data) {
    final paymentMap = data?['payment'] as Map<String, dynamic>? ?? const {};
    final waMap = data?['whatsapp'] as Map<String, dynamic>? ?? const {};
    return SendPaymentLinkResult(
      payment: SnippePaymentSession.fromJson(paymentMap),
      whatsappSuccess: waMap['success'] == true,
      whatsappError: waMap['error'] as String?,
      whatsappMessageId: waMap['messageId'] as String?,
    );
  }
}
