import 'dart:convert';

import 'package:get_storage/get_storage.dart';

/// Persisted smart-lock entry log (offline-first; no backend table yet).
class StoredEntryLog {
  const StoredEntryLog({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.detail,
    required this.iconType,
    required this.status,
    required this.occurredAtMs,
    this.isAppUnlock = false,
    this.isPinCode = false,
    this.source = 'local',
  });

  final String id;
  final String deviceId;
  final String title;
  final String detail;
  final String iconType;
  final String status;
  final int occurredAtMs;
  final bool isAppUnlock;
  final bool isPinCode;
  final String source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'title': title,
        'detail': detail,
        'iconType': iconType,
        'status': status,
        'occurredAtMs': occurredAtMs,
        'isAppUnlock': isAppUnlock,
        'isPinCode': isPinCode,
        'source': source,
      };

  factory StoredEntryLog.fromJson(Map<String, dynamic> json) {
    return StoredEntryLog(
      id: json['id']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      iconType: json['iconType']?.toString() ?? 'lock',
      status: json['status']?.toString() ?? 'completed',
      occurredAtMs: json['occurredAtMs'] is int
          ? json['occurredAtMs'] as int
          : int.tryParse(json['occurredAtMs']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
      isAppUnlock: json['isAppUnlock'] == true,
      isPinCode: json['isPinCode'] == true,
      source: json['source']?.toString() ?? 'local',
    );
  }
}

class EntryLogsStore {
  EntryLogsStore() : _box = GetStorage();

  static const _key = 'entry_logs_v1';
  static const _metaKey = 'entry_logs_meta_v1';

  final GetStorage _box;

  List<StoredEntryLog> loadAll() {
    final raw = _box.read(_key);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => StoredEntryLog.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList()
        ..sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
    }
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => StoredEntryLog.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty)
              .toList()
            ..sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveAll(List<StoredEntryLog> logs) async {
    final sorted = List<StoredEntryLog>.from(logs)
      ..sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
    await _box.write(_key, sorted.map((e) => e.toJson()).toList());
  }

  Future<void> upsert(StoredEntryLog log) async {
    final all = loadAll();
    final idx = all.indexWhere((e) => e.id == log.id);
    if (idx >= 0) {
      all[idx] = log;
    } else {
      all.insert(0, log);
    }
    await saveAll(all);
  }

  EntryLogsMeta? loadMeta() {
    final raw = _box.read(_metaKey);
    if (raw is Map) {
      return EntryLogsMeta.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> saveMeta(EntryLogsMeta meta) async {
    await _box.write(_metaKey, meta.toJson());
  }
}

class EntryLogsMeta {
  const EntryLogsMeta({
    this.deviceId,
    this.deviceName,
    this.locationName,
    this.lastSyncedMs,
  });

  final String? deviceId;
  final String? deviceName;
  final String? locationName;
  final int? lastSyncedMs;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'locationName': locationName,
        'lastSyncedMs': lastSyncedMs,
      };

  factory EntryLogsMeta.fromJson(Map<String, dynamic> json) {
    return EntryLogsMeta(
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      locationName: json['locationName']?.toString(),
      lastSyncedMs: json['lastSyncedMs'] is int
          ? json['lastSyncedMs'] as int
          : int.tryParse(json['lastSyncedMs']?.toString() ?? ''),
    );
  }
}
