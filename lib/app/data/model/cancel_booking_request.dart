/// Request body for cancelling a guest booking.
class CancelBookingRequest {
  CancelBookingRequest({required this.bookingId});

  final String bookingId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bookingId': bookingId,
      };

  static CancelBookingRequest fromJson(Map<String, dynamic> json) {
    return CancelBookingRequest(
      bookingId: json['bookingId'] as String? ?? '',
    );
  }
}
