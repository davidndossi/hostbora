/// Request body for recording a payment (POST /api/payments).
class RecordPaymentRequest {
  RecordPaymentRequest({
    required this.amount,
    required this.paymentMethod,
    this.bookingId,
    required this.paymentDate,
    required this.status,
    this.idempotencyKey,
  });

  final double amount;
  final String paymentMethod;
  final String? bookingId;
  /// ISO date string (yyyy-MM-dd).
  final String paymentDate;
  /// 'PAID' or 'PENDING'
  final String status;
  /// Offline-queue dedupe key; sent as body + Idempotency-Key header.
  final String? idempotencyKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (bookingId != null && bookingId!.isNotEmpty) 'bookingId': bookingId,
      'paymentDate': paymentDate,
      'status': status,
      if (idempotencyKey != null && idempotencyKey!.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
  }

  static RecordPaymentRequest fromJson(Map<String, dynamic> json) {
    return RecordPaymentRequest(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      bookingId: json['bookingId'] as String?,
      paymentDate: json['paymentDate'] as String? ?? '',
      status: json['status'] as String? ?? 'PAID',
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }
}
