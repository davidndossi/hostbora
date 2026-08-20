import '../../core/models/item_sync_status.dart';

/// BnB booking row for home, all bookings, and booking details.
class CheckInItem {
  const CheckInItem({
    this.bookingId,
    this.checkInIso = '',
    this.checkOutIso = '',
    this.listingId,
    this.isLocalPending = false,
    this.syncStatus = ItemSyncStatus.synced,
    this.syncQueueId,
    this.isCheckedOut = false,
    this.isCancelled = false,
    required this.imageUrl,
    required this.guestName,
    this.guestPhone = '',
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
  final ItemSyncStatus syncStatus;
  final int? syncQueueId;
  final bool isCheckedOut;
  final bool isCancelled;
  final String imageUrl;
  final String guestName;
  final String guestPhone;
  final String guestAvatarUrl;
  final String propertyType;
  final String dates;
  final bool isConfirmed;

  String get bookingKey =>
      bookingId ?? '${guestName}_$checkInIso';

  /// Guest+date fallback used when API id and local override keys diverge.
  String get guestCheckInKey => '${guestName}_$checkInIso';

  bool get isInactive => isCheckedOut || isCancelled;

  bool get canCheckOut => !isInactive;

  bool get canExtendStay => !isInactive;

  bool get canCancel => !isInactive;

  bool get showSyncBadge => syncStatus.showSyncBadge;

  CheckInItem copyWith({
    String? bookingId,
    String? checkInIso,
    String? checkOutIso,
    String? listingId,
    bool? isLocalPending,
    ItemSyncStatus? syncStatus,
    int? syncQueueId,
    bool? isCheckedOut,
    bool? isCancelled,
    String? imageUrl,
    String? guestName,
    String? guestPhone,
    String? guestAvatarUrl,
    String? propertyType,
    String? dates,
    bool? isConfirmed,
  }) {
    return CheckInItem(
      bookingId: bookingId ?? this.bookingId,
      checkInIso: checkInIso ?? this.checkInIso,
      checkOutIso: checkOutIso ?? this.checkOutIso,
      listingId: listingId ?? this.listingId,
      isLocalPending: isLocalPending ?? this.isLocalPending,
      syncStatus: syncStatus ?? this.syncStatus,
      syncQueueId: syncQueueId ?? this.syncQueueId,
      isCheckedOut: isCheckedOut ?? this.isCheckedOut,
      isCancelled: isCancelled ?? this.isCancelled,
      imageUrl: imageUrl ?? this.imageUrl,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      guestAvatarUrl: guestAvatarUrl ?? this.guestAvatarUrl,
      propertyType: propertyType ?? this.propertyType,
      dates: dates ?? this.dates,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}
