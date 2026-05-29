import 'dart:convert';

import 'package:get_storage/get_storage.dart';

/// Local overrides for BnB bookings (check-out date changes, checked-out status).
///
/// Applied on top of API and [PendingBookingsStore] data until sync completes.
class BnbBookingOverridesStore {
  BnbBookingOverridesStore() : _box = GetStorage();

  static const _key = 'bnb_booking_overrides';

  final GetStorage _box;

  Map<String, Map<String, dynamic>> _loadAll() {
    final raw = _box.read(_key);
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
        ),
      );
    }
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return decoded.map(
            (k, v) => MapEntry(
              k.toString(),
              v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
            ),
          );
        }
      } catch (_) {}
    }
    return {};
  }

  Future<void> _saveAll(Map<String, Map<String, dynamic>> all) async {
    await _box.write(_key, all);
  }

  Map<String, dynamic>? get(String bookingKey) => _loadAll()[bookingKey];

  bool isCheckedOut(String bookingKey) {
    final o = get(bookingKey);
    return o?['status']?.toString() == 'checked_out';
  }

  bool isCancelled(String bookingKey) {
    final o = get(bookingKey);
    return o?['status']?.toString() == 'cancelled';
  }

  String? effectiveCheckOut(String bookingKey, String fallbackIso) {
    final o = get(bookingKey);
    final co = o?['checkOut']?.toString().trim();
    return co != null && co.isNotEmpty ? co : fallbackIso;
  }

  Future<void> markCheckedOut(String bookingKey) async {
    final all = _loadAll();
    final existing = Map<String, dynamic>.from(all[bookingKey] ?? {});
    existing['status'] = 'checked_out';
    existing['checkedOutAt'] = DateTime.now().toIso8601String();
    all[bookingKey] = existing;
    await _saveAll(all);
  }

  Future<void> markCancelled(String bookingKey) async {
    final all = _loadAll();
    final existing = Map<String, dynamic>.from(all[bookingKey] ?? {});
    existing['status'] = 'cancelled';
    existing['cancelledAt'] = DateTime.now().toIso8601String();
    all[bookingKey] = existing;
    await _saveAll(all);
  }

  Future<void> clearCancelled(String bookingKey) async {
    final all = _loadAll();
    final existing = Map<String, dynamic>.from(all[bookingKey] ?? {});
    existing.remove('status');
    existing.remove('cancelledAt');
    if (existing.isEmpty) {
      all.remove(bookingKey);
    } else {
      all[bookingKey] = existing;
    }
    await _saveAll(all);
  }

  Future<void> setCheckOut(String bookingKey, String checkOutIso) async {
    final all = _loadAll();
    final existing = Map<String, dynamic>.from(all[bookingKey] ?? {});
    existing['checkOut'] = checkOutIso;
    all[bookingKey] = existing;
    await _saveAll(all);
  }
}
