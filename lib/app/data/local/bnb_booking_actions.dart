import 'dart:convert';

import 'package:intl/intl.dart';

import '../model/cancel_booking_request.dart';
import '../model/checkout_booking_request.dart';
import '../model/update_booking_request.dart';
import 'bnb_booking_overrides_store.dart';
import 'db/offline_sync_queue_local_data_source.dart';
import 'pending_bookings_store.dart';
import 'service/offline_sync_worker_service.dart';

/// Offline-first checkout and extend-stay for BnB bookings.
class BnbBookingActions {
  BnbBookingActions({
    OfflineSyncQueueLocalDataSource? syncQueue,
    OfflineSyncWorkerService? syncWorker,
    BnbBookingOverridesStore? overrides,
    PendingBookingsStore? pending,
  })  : _syncQueue = syncQueue,
        _syncWorker = syncWorker,
        _overrides = overrides ?? BnbBookingOverridesStore(),
        _pending = pending ?? PendingBookingsStore();

  final OfflineSyncQueueLocalDataSource? _syncQueue;
  final OfflineSyncWorkerService? _syncWorker;
  final BnbBookingOverridesStore _overrides;
  final PendingBookingsStore _pending;

  static const _isoDateFormat = 'yyyy-MM-dd';

  Future<void> checkOut({
    required String bookingKey,
    required bool isLocalPending,
  }) async {
    await _overrides.markCheckedOut(bookingKey);

    if (isLocalPending) {
      return;
    }

    final payload = CheckoutBookingRequest(bookingId: bookingKey).toJson();
    await _enqueue(
      operation: 'checkout',
      payload: payload,
      dedupeKey: 'booking:checkout:$bookingKey',
    );
  }

  Future<void> cancelBooking({
    required String bookingKey,
    required bool isLocalPending,
  }) async {
    if (isLocalPending) {
      await _removePendingBooking(bookingKey);
      return;
    }

    await _overrides.markCancelled(bookingKey);
    final payload = CancelBookingRequest(bookingId: bookingKey).toJson();
    await _enqueue(
      operation: 'cancel',
      payload: payload,
      dedupeKey: 'booking:cancel:$bookingKey',
    );
  }

  Future<void> extendStay({
    required String bookingKey,
    required bool isLocalPending,
    required DateTime newCheckOut,
  }) async {
    final checkOutIso = DateFormat(_isoDateFormat).format(newCheckOut);
    await _overrides.setCheckOut(bookingKey, checkOutIso);

    if (isLocalPending) {
      await _updatePendingCheckOut(bookingKey, checkOutIso);
      return;
    }

    final payload = UpdateBookingRequest(
      bookingId: bookingKey,
      checkOut: checkOutIso,
    ).toJson();
    await _enqueue(
      operation: 'update',
      payload: payload,
      dedupeKey: 'booking:update:$bookingKey',
    );
  }

  Future<void> _removePendingBooking(String localId) async {
    final list = _pending.load();
    for (var i = 0; i < list.length; i++) {
      final createdAt = (list[i]['createdAt'] ?? '').toString();
      final listingId = (list[i]['listingId'] ?? '').toString();
      final checkIn = (list[i]['checkIn'] ?? '').toString();
      final key = 'local_${createdAt.isNotEmpty ? createdAt : '${listingId}_$checkIn'}';
      if (key == localId) {
        list.removeAt(i);
        await _pending.save(list);
        return;
      }
    }
  }

  Future<void> _updatePendingCheckOut(String localId, String checkOutIso) async {
    final list = _pending.load();
    for (var i = 0; i < list.length; i++) {
      final createdAt = (list[i]['createdAt'] ?? '').toString();
      final listingId = (list[i]['listingId'] ?? '').toString();
      final checkIn = (list[i]['checkIn'] ?? '').toString();
      final key = 'local_${createdAt.isNotEmpty ? createdAt : '${listingId}_$checkIn'}';
      if (key == localId) {
        list[i] = {...list[i], 'checkOut': checkOutIso};
        await _pending.save(list);
        return;
      }
    }
  }

  Future<void> _enqueue({
    required String operation,
    required Map<String, dynamic> payload,
    required String dedupeKey,
  }) async {
    final queue = _syncQueue;
    if (queue == null) return;
    await queue.enqueue(
      entityType: 'booking',
      operation: operation,
      payloadJson: jsonEncode(payload),
      dedupeKey: dedupeKey,
    );
    await _syncWorker?.runNow(maxItems: 20);
  }
}
