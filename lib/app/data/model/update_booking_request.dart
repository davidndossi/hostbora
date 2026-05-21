/// Request body for updating booking dates (extend stay).
class UpdateBookingRequest {
  UpdateBookingRequest({
    required this.bookingId,
    required this.checkOut,
  });

  final String bookingId;
  final String checkOut;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bookingId': bookingId,
        'checkOut': checkOut,
      };

  static UpdateBookingRequest fromJson(Map<String, dynamic> json) {
    return UpdateBookingRequest(
      bookingId: json['bookingId'] as String? ?? '',
      checkOut: json['checkOut'] as String? ?? '',
    );
  }
}
