import 'dart:convert';

import '../../core/models/item_sync_status.dart';
import '../../core/utils/bnb_property_listing.dart';
import '../model/check_in_item.dart';
import 'bnb_booking_merge.dart';
import 'db/offline_sync_queue_local_data_source.dart';
import 'db/property_local_data_source.dart';
import 'pending_bookings_store.dart';

/// Loads pending booking payloads from legacy storage and the offline sync queue.
class BnbBookingPendingLoader {
  BnbBookingPendingLoader({
    PendingBookingsStore? legacyPending,
    OfflineSyncQueueLocalDataSource? syncQueue,
  })  : _legacy = legacyPending ?? PendingBookingsStore(),
        _syncQueue = syncQueue;

  final PendingBookingsStore _legacy;
  final OfflineSyncQueueLocalDataSource? _syncQueue;

  /// Each map is compatible with [BnbBookingMerge.fromPendingMap] (`listingId`, `checkIn`, `checkOut`, `guestName`, `createdAt`).
  Future<List<Map<String, dynamic>>> loadAll() async {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    void add(Map<String, dynamic> m, String dedupeKey) {
      if (seen.add(dedupeKey)) out.add(m);
    }

    for (final m in _legacy.load()) {
      final listingId = (m['listingId'] ?? '').toString();
      final checkIn = (m['checkIn'] ?? '').toString();
      final createdAt = (m['createdAt'] ?? '').toString();
      add(
        <String, dynamic>{
          ...m,
          'syncStatus': 'pending',
        },
        'legacy:$listingId|$checkIn|$createdAt',
      );
    }

    final queue = _syncQueue;
    if (queue != null) {
      for (final item in await queue.listUnsyncedBookingCreates()) {
        try {
          final decoded = jsonDecode(item.payloadJson);
          if (decoded is! Map) continue;
          final map = Map<String, dynamic>.from(decoded);
          final withMeta = <String, dynamic>{
            ...map,
            'createdAt': DateTime.fromMillisecondsSinceEpoch(item.createdAtMs)
                .toIso8601String(),
            'syncStatus': item.status,
            'syncQueueId': item.id,
          };
          final listingId = (map['listingId'] ?? '').toString();
          final checkIn = (map['checkIn'] ?? '').toString();
          add(withMeta, 'sync:${item.id}|$listingId|$checkIn');
        } catch (_) {}
      }
    }

    return out;
  }
}

/// Merges legacy + sync-queue pending bookings into [merged].
Future<void> mergePendingBnbBookings({
  required BnbBookingMerge merge,
  required Map<String, CheckInItem> merged,
  required List<PropertyRecord> properties,
  required BnbBookingPendingLoader loader,
}) async {
  for (final m in await loader.loadAll()) {
    final listingId = (m['listingId'] ?? '').toString().trim();
    final checkIn = (m['checkIn'] ?? '').toString();
    final checkOut = (m['checkOut'] ?? '').toString();
    if (listingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) continue;

    final property = findBnbPropertyForListing(listingId, properties);
    final propertyLabel = property?.propertyName.trim().isNotEmpty == true
        ? property!.propertyName.trim()
        : (property?.propertyLocation ?? 'Property');
    final syncQueueId = m['syncQueueId'] as int?;
    final localId = syncQueueId != null
        ? 'local_sync_$syncQueueId'
        : 'local_${m['createdAt'] ?? '${listingId}_$checkIn'}';
    final pendingMap = Map<String, dynamic>.from(m);
    if (property != null) {
      pendingMap['listingId'] = bnbHubRefForProperty(property);
    }
    final item = merge.fromPendingMap(
      pendingMap,
      propertyLabel: propertyLabel,
      localId: localId,
      syncStatus: ItemSyncStatusX.fromQueueStatus(m['syncStatus']?.toString()),
      syncQueueId: syncQueueId,
    );
    final imageUrl = resolveBnbBookingPropertyImage(
      listingId: item.listingId,
      propertyLabel: propertyLabel,
      properties: properties,
    );
    final withImage =
        imageUrl.isEmpty ? item : item.copyWith(imageUrl: imageUrl);
    // Keep cancelled rows so UI can show the Cancelled badge; drop check-outs.
    if (withImage.isCheckedOut) continue;
    merged[localId] = withImage;
  }
}
