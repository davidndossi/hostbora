/// BnB booking row for home, all bookings, and booking details.
class CheckInItem {
  const CheckInItem({
    this.bookingId,
    this.checkInIso = '',
    this.checkOutIso = '',
    this.listingId,
    this.isLocalPending = false,
    this.isCheckedOut = false,
    this.isCancelled = false,
    required this.imageUrl,
    required this.guestName,
    required this.guestAvatarUrl,
    required this.propertyType,
    required this.dates,
    required this.isConfirmed,
  });

  final String? bookingId;
  final String checkInIso;
  final String checkOutIso;
  final String? listingId;
  final bool isLocalPending;
  final bool isCheckedOut;
  final bool isCancelled;
  final String imageUrl;
  final String guestName;
  final String guestAvatarUrl;
  final String propertyType;
  final String dates;
  final bool isConfirmed;

  String get bookingKey =>
      bookingId ?? '${guestName}_$checkInIso';

  bool get isInactive => isCheckedOut || isCancelled;

  bool get canCheckOut => !isInactive;

  bool get canExtendStay => !isInactive;

  bool get canCancel => !isInactive;
}
