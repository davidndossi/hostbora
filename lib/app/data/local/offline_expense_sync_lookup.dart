import 'dart:convert';

import '../../core/models/item_sync_status.dart';
import 'db/offline_sync_queue_local_data_source.dart';

class OfflineExpenseSyncLookup {
  const OfflineExpenseSyncLookup({
    required this.statusByLocalId,
    required this.queueIdByLocalId,
  });

  final Map<int, ItemSyncStatus> statusByLocalId;
  final Map<int, int> queueIdByLocalId;

  ItemSyncStatus statusFor(int localExpenseId) =>
      statusByLocalId[localExpenseId] ?? ItemSyncStatus.synced;

  int? queueIdFor(int localExpenseId) => queueIdByLocalId[localExpenseId];

  static Future<OfflineExpenseSyncLookup> load(
    OfflineSyncQueueLocalDataSource queue,
  ) async {
    final statusByLocalId = <int, ItemSyncStatus>{};
    final queueIdByLocalId = <int, int>{};
    final items = await queue.listUnsynced(
      entityType: 'expense',
      operation: 'create',
    );
    for (final item in items) {
      try {
        final decoded = jsonDecode(item.payloadJson);
        if (decoded is! Map) continue;
        final rawId = decoded['localExpenseId'];
        final localId = rawId is int
            ? rawId
            : rawId is num
                ? rawId.toInt()
                : int.tryParse('$rawId');
        if (localId == null) continue;
        statusByLocalId[localId] = ItemSyncStatusX.fromQueueStatus(item.status);
        queueIdByLocalId[localId] = item.id;
      } catch (_) {}
    }
    return OfflineExpenseSyncLookup(
      statusByLocalId: statusByLocalId,
      queueIdByLocalId: queueIdByLocalId,
    );
  }
}
