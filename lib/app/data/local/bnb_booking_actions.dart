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
    // Local status is already updated; sync failures must not block the UI.
    await _enqueueBestEffort(
      operation: 'checkout',
      payload: payload,
      dedupeKey: 'booking:checkout:$bookingKey',
    );
  }

  Future<void> cancelBooking({
    required String bookingKey,
    required bool isLocalPending,
    int? syncQueueId,
    Iterable<String> aliasKeys = const [],
  }) async {
    // Always write the override first so Home/All Bookings never reload as
    // "Confirmed" if a pending row is still briefly visible.
    await _overrides.markCancelled(bookingKey, aliases: aliasKeys);

    if (isLocalPending) {
      await _removePendingBooking(
        bookingKey,
        syncQueueId: syncQueueId,
      );
      return;
    }

    final payload = CancelBookingRequest(bookingId: bookingKey).toJson();
    // Local status is already "cancelled"; sync failures must not block the UI.
    await _enqueueBestEffort(
      operation: 'cancel',
      payload: payload,
      dedupeKey: 'booking:cancel:$bookingKey',
    );
  }

  /// Captures a pending offline booking row before [cancelBooking] removes it.
  Future<Map<String, dynamic>?> snapshotPendingBooking(String localId) async {
    final list = _pending.load();
    for (final m in list) {
      final createdAt = (m['createdAt'] ?? '').toString();
      final listingId = (m['listingId'] ?? '').toString();
      final checkIn = (m['checkIn'] ?? '').toString();
      final key = 'local_${createdAt.isNotEmpty ? createdAt : '${listingId}_$checkIn'}';
      if (key == localId) {
        return Map<String, dynamic>.from(m);
      }
    }
    return null;
  }

  Future<void> restorePendingBooking(Map<String, dynamic> snapshot) async {
    final list = _pending.load();
    list.add(Map<String, dynamic>.from(snapshot));
    await _pending.save(list);
  }

  Future<void> undoCancelBooking({
    required String bookingKey,
    required bool wasLocalPending,
    Map<String, dynamic>? pendingSnapshot,
    Iterable<String> aliasKeys = const [],
  }) async {
    if (wasLocalPending && pendingSnapshot != null) {
      await restorePendingBooking(pendingSnapshot);
      return;
    }
    await _overrides.clearCancelled(bookingKey, aliases: aliasKeys);
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
    await _enqueueBestEffort(
      operation: 'update',
      payload: payload,
      dedupeKey: 'booking:update:$bookingKey',
    );
  }

  Future<void> _removePendingBooking(
    String localId, {
    int? syncQueueId,
  }) async {
    // Failed offline creates use `local_sync_<queueId>` — not the legacy
    // `local_<createdAt>` key. Drop the queue row or cancel is a no-op and
    // Home reloads the booking as Confirmed again.
    final queueId = syncQueueId ?? _syncQueueIdFromLocalId(localId);
    final queue = _syncQueue;
    if (queueId != null && queue != null) {
      await queue.markDone(queueId);
    }

    final list = _pending.load();
    for (var i = 0; i < list.length; i++) {
      final createdAt = (list[i]['createdAt'] ?? '').toString();
      final listingId = (list[i]['listingId'] ?? '').toString();
      final checkIn = (list[i]['checkIn'] ?? '').toString();
      final key =
          'local_${createdAt.isNotEmpty ? createdAt : '${listingId}_$checkIn'}';
      if (key == localId) {
        list.removeAt(i);
        await _pending.save(list);
        return;
      }
    }
  }

  static int? _syncQueueIdFromLocalId(String localId) {
    const prefix = 'local_sync_';
    if (!localId.startsWith(prefix)) return null;
    return int.tryParse(localId.substring(prefix.length));
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

  Future<void> _enqueueBestEffort({
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
    try {
      await _syncWorker?.runNow(maxItems: 20);
    } catch (_) {
      // Keep queued for retry. Caller already applied the local override.
    }
  }
}
