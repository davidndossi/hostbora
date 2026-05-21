/// Calendar iCal subscription (import from OTA or export to OTA).
class CalendarSubscription {
  CalendarSubscription({
    required this.id,
    required this.listingId,
    required this.direction,
    this.unitId,
    this.sourceUrl,
    this.exportToken,
    this.exportUrl,
    this.label,
    this.lastSyncAtMs,
    this.lastSyncStatus,
    this.lastSyncMessage,
    this.enabled = true,
  });

  final String id;
  final String listingId;
  final String direction;
  final String? unitId;
  final String? sourceUrl;
  final String? exportToken;
  final String? exportUrl;
  final String? label;
  final int? lastSyncAtMs;
  final String? lastSyncStatus;
  final String? lastSyncMessage;
  final bool enabled;

  bool get isImport => direction.toUpperCase() == 'IMPORT';
  bool get isExport => direction.toUpperCase() == 'EXPORT';

  factory CalendarSubscription.fromJson(Map<String, dynamic> json) {
    return CalendarSubscription(
      id: (json['id'] ?? '').toString(),
      listingId: (json['listingId'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
      unitId: json['unitId']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
      exportToken: json['exportToken']?.toString(),
      exportUrl: json['exportUrl']?.toString(),
      label: json['label']?.toString(),
      lastSyncAtMs: asIntOrNull(json['lastSyncAt']),
      lastSyncStatus: json['lastSyncStatus']?.toString(),
      lastSyncMessage: json['lastSyncMessage']?.toString(),
      enabled: json['enabled'] != false,
    );
  }

  static int? asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Result of POST /api/calendar/import/sync.
class CalendarSyncResult {
  CalendarSyncResult({
    required this.subscriptionId,
    required this.listingId,
    required this.status,
    required this.message,
    this.importedCount = 0,
  });

  final String subscriptionId;
  final String listingId;
  final String status;
  final String message;
  final int importedCount;

  factory CalendarSyncResult.fromJson(Map<String, dynamic> json) {
    return CalendarSyncResult(
      subscriptionId: (json['subscriptionId'] ?? '').toString(),
      listingId: (json['listingId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      importedCount: CalendarSubscription.asIntOrNull(json['importedCount']) ?? 0,
    );
  }
}
