/// UI sync state for offline-first rows (bookings, expenses, etc.).
enum ItemSyncStatus {
  synced,
  pending,
  syncing,
  failed,
}

extension ItemSyncStatusX on ItemSyncStatus {
  bool get showSyncBadge =>
      this == ItemSyncStatus.pending ||
      this == ItemSyncStatus.syncing ||
      this == ItemSyncStatus.failed;

  static ItemSyncStatus fromQueueStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'failed':
        return ItemSyncStatus.failed;
      case 'in_progress':
        return ItemSyncStatus.syncing;
      case 'pending':
        return ItemSyncStatus.pending;
      case 'done':
        return ItemSyncStatus.synced;
      default:
        return ItemSyncStatus.pending;
    }
  }
}
