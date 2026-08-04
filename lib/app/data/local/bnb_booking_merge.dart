import 'package:intl/intl.dart';

import '../../core/models/item_sync_status.dart';
import '../../core/utils/bnb_stay_billing.dart';
import '../model/check_in_item.dart';
import 'bnb_booking_overrides_store.dart';
import 'pending_bookings_store.dart';

/// Merges remote API rows, pending offline creates, and local overrides into [CheckInItem]s.
class BnbBookingMerge {
  BnbBookingMerge({
    BnbBookingOverridesStore? overrides,
    PendingBookingsStore? pending,
  })  : _overrides = overrides ?? BnbBookingOverridesStore(),
        _pending = pending ?? PendingBookingsStore();

  final BnbBookingOverridesStore _overrides;
  final PendingBookingsStore _pending;

  CheckInItem fromApiMap(Map<String, dynamic> m) {
    final checkIn = (m['checkIn'] ?? '').toString();
    final rawCheckOut = (m['checkOut'] ?? '').toString();
    final nights = (m['numberOfNights'] as num?)?.toInt() ?? 0;
    final guestName = (m['guestName'] ?? '').toString();
    final key = resolveBookingKey(m, checkIn: checkIn, guestName: guestName);
    final checkOut = _overrides.effectiveCheckOut(key, rawCheckOut) ?? rawCheckOut;
    final status = (m['status'] ?? '').toString().trim().toLowerCase();
    final checkedOut = _overrides.isCheckedOut(key) ||
        status == 'checked_out' ||
        status == 'completed';
    final cancelled = _overrides.isCancelled(key) ||
        status == 'cancelled' ||
        status == 'canceled';
    final confirmedFlag = m['isConfirmed'];
    final confirmed = !cancelled &&
        !checkedOut &&
        (confirmedFlag is bool
            ? confirmedFlag
            : status.isEmpty || status == 'confirmed' || status == 'active');

    return CheckInItem(
      bookingId: key,
      checkInIso: checkIn,
      checkOutIso: checkOut,
      listingId: (m['listingId'] ?? m['propertyId'] ?? '').toString(),
      isLocalPending: false,
      isCheckedOut: checkedOut,
      isCancelled: cancelled,
      imageUrl: (m['imageUrl'] ?? '').toString(),
      guestName: guestName,
      guestPhone: (m['guestPhoneNumber'] ?? m['guestPhone'] ?? '').toString(),
      guestAvatarUrl: (m['guestAvatarUrl'] ?? '').toString(),
      propertyType: (m['propertyType'] ?? m['propertyName'] ?? '').toString(),
      dates: formatDates(checkIn, checkOut, nights),
      isConfirmed: confirmed,
    );
  }

  /// Stable id used for overrides, cancel/checkout, and list merge.
  static String resolveBookingKey(
    Map<String, dynamic> m, {
    required String checkIn,
    required String guestName,
  }) {
    for (final field in ['bookingId', 'id', 'booking_id']) {
      final raw = m[field]?.toString().trim() ?? '';
      if (raw.isNotEmpty) return raw;
    }
    return '${guestName}_$checkIn';
  }

  CheckInItem fromPendingMap(
    Map<String, dynamic> m, {
    required String propertyLabel,
    required String localId,
    ItemSyncStatus syncStatus = ItemSyncStatus.pending,
    int? syncQueueId,
  }) {
    final checkIn = (m['checkIn'] ?? '').toString();
    final rawCheckOut = (m['checkOut'] ?? '').toString();
    final checkOut = _overrides.effectiveCheckOut(localId, rawCheckOut) ?? rawCheckOut;
    final checkedOut = _overrides.isCheckedOut(localId);
    final cancelled = _overrides.isCancelled(localId);

    return CheckInItem(
      bookingId: localId,
      checkInIso: checkIn,
      checkOutIso: checkOut,
      listingId: (m['listingId'] ?? '').toString(),
      isLocalPending: true,
      syncStatus: syncStatus,
      syncQueueId: syncQueueId,
      isCheckedOut: checkedOut,
      isCancelled: cancelled,
      imageUrl: '',
      guestName: (m['guestName'] ?? '').toString(),
      guestPhone: (m['guestPhoneNumber'] ?? m['guestPhone'] ?? '').toString(),
      guestAvatarUrl: '',
      propertyType: propertyLabel,
      dates: formatDates(checkIn, checkOut, 0),
      isConfirmed: !cancelled && !checkedOut,
    );
  }

  static String formatDates(String checkIn, String checkOut, int nights) {
    try {
      final ci = DateTime.tryParse(checkIn);
      final co = DateTime.tryParse(checkOut);
      if (ci != null && co != null) {
        final fmt = DateFormat('MMM d');
        final calculated = BnbStayBilling.nightsBetween(ci, co);
        final n = calculated > 0 ? calculated : (nights > 0 ? nights : 0);
        return '${fmt.format(ci)} - ${fmt.format(co)} • $n Night${n == 1 ? '' : 's'}';
      }
    } catch (_) {}
    return '$checkIn - $checkOut';
  }

  PendingBookingsStore get pendingStore => _pending;

  BnbBookingOverridesStore get overridesStore => _overrides;
}
