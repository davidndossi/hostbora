/// Request body for creating a booking (add booking flow).
class CreateBookingRequest {
  CreateBookingRequest({
    required this.listingId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    this.numberOfGuests = 1,
    this.notes,
    this.guestPhoneNumber,
  });

  final String listingId;
  final String guestName;
  /// ISO date string (yyyy-MM-dd).
  final String checkIn;
  /// ISO date string (yyyy-MM-dd).
  final String checkOut;
  final int numberOfGuests;
  final String? notes;
  /// Guest phone number (e.g. for push-to-pay). Optional.
  final String? guestPhoneNumber;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'listingId': listingId,
      'guestName': guestName,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'numberOfGuests': numberOfGuests,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (guestPhoneNumber != null && guestPhoneNumber!.trim().isNotEmpty)
        'guestPhoneNumber': guestPhoneNumber!.trim(),
    };
  }

  static CreateBookingRequest fromJson(Map<String, dynamic> json) {
    return CreateBookingRequest(
      listingId: json['listingId'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      checkIn: json['checkIn'] as String? ?? '',
      checkOut: json['checkOut'] as String? ?? '',
      numberOfGuests: (json['numberOfGuests'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      guestPhoneNumber: json['guestPhoneNumber'] as String?,
    );
  }
}
