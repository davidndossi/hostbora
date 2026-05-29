import 'dart:convert';

import '../../core/models/item_sync_status.dart';
import 'db/offline_sync_queue_local_data_source.dart';

/// Maps unsynced payment queue payloads to booking ids for sync badges.
class OfflinePaymentSyncLookup {
  const OfflinePaymentSyncLookup({
    required this.statusByBookingId,
    required this.queueIdByBookingId,
  });

  final Map<String, ItemSyncStatus> statusByBookingId;
  final Map<String, int> queueIdByBookingId;

  ItemSyncStatus statusForBooking(String bookingId) {
    final key = bookingId.trim();
    if (key.isEmpty) return ItemSyncStatus.synced;
    return statusByBookingId[key] ?? ItemSyncStatus.synced;
  }

  int? queueIdForBooking(String bookingId) {
    final key = bookingId.trim();
    if (key.isEmpty) return null;
    return queueIdByBookingId[key];
  }

  static Future<OfflinePaymentSyncLookup> load(
    OfflineSyncQueueLocalDataSource queue,
  ) async {
    final statusByBookingId = <String, ItemSyncStatus>{};
    final queueIdByBookingId = <String, int>{};
    final items = await queue.listUnsynced(
      entityType: 'payment',
      operation: 'create',
    );
    for (final item in items) {
      try {
        final decoded = jsonDecode(item.payloadJson);
        if (decoded is! Map) continue;
        final bookingId = (decoded['bookingId'] ?? '').toString().trim();
        if (bookingId.isEmpty) continue;
        final status = ItemSyncStatusX.fromQueueStatus(item.status);
        final existing = statusByBookingId[bookingId];
        statusByBookingId[bookingId] = _mergeStatus(existing, status);
        if (status == ItemSyncStatus.failed ||
            !queueIdByBookingId.containsKey(bookingId)) {
          queueIdByBookingId[bookingId] = item.id;
        }
      } catch (_) {}
    }
    return OfflinePaymentSyncLookup(
      statusByBookingId: statusByBookingId,
      queueIdByBookingId: queueIdByBookingId,
    );
  }

  static ItemSyncStatus _mergeStatus(
    ItemSyncStatus? existing,
    ItemSyncStatus incoming,
  ) {
    if (existing == null) return incoming;
    if (existing == ItemSyncStatus.failed ||
        incoming == ItemSyncStatus.failed) {
      return ItemSyncStatus.failed;
    }
    if (existing == ItemSyncStatus.syncing ||
        incoming == ItemSyncStatus.syncing) {
      return ItemSyncStatus.syncing;
    }
    return ItemSyncStatus.pending;
  }
}
