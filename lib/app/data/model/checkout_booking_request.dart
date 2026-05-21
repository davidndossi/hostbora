/// Request body for checking out a guest booking.
class CheckoutBookingRequest {
  CheckoutBookingRequest({required this.bookingId});

  final String bookingId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bookingId': bookingId,
      };

  static CheckoutBookingRequest fromJson(Map<String, dynamic> json) {
    return CheckoutBookingRequest(
      bookingId: json['bookingId'] as String? ?? '',
    );
  }
}
