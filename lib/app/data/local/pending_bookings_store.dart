import 'dart:convert';

import 'package:get_storage/get_storage.dart';

/// Persists booking requests when offline. Sync when back online.
class PendingBookingsStore {
  PendingBookingsStore() : _box = GetStorage();

  static const _key = 'pending_bookings';

  final GetStorage _box;

  List<Map<String, dynamic>> load() {
    final raw = _box.read(_key);
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m['listingId'] != null && m['checkIn'] != null)
          .toList();
    }
    if (raw is String) {
      try {
        final decoded = json.decode(raw) as List<dynamic>?;
        return (decoded ?? [])
            .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
            .where((m) => m['listingId'] != null && m['checkIn'] != null)
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> add(Map<String, dynamic> requestJson) async {
    final list = load();
    list.add({
      ...requestJson,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _box.write(_key, list);
  }

  Future<void> save(List<Map<String, dynamic>> list) async {
    await _box.write(_key, list);
  }

  Future<void> removeAt(int index) async {
    final list = load();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await save(list);
    }
  }

  int get count => load().length;
}
