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
    return _statusIs(bookingKey, 'checked_out');
  }

  bool isCancelled(String bookingKey) {
    return _statusIs(bookingKey, 'cancelled');
  }

  /// True when any of [keys] is marked cancelled (API id vs guest_date aliases).
  bool isCancelledForAny(Iterable<String> keys) {
    for (final k in keys) {
      if (isCancelled(k.trim())) return true;
    }
    return false;
  }

  bool isCheckedOutForAny(Iterable<String> keys) {
    for (final k in keys) {
      if (isCheckedOut(k.trim())) return true;
    }
    return false;
  }

  bool _statusIs(String bookingKey, String status) {
    final key = bookingKey.trim();
    if (key.isEmpty) return false;
    final o = get(key);
    return o?['status']?.toString() == status;
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

  /// Marks cancelled under [bookingKey] and optional [aliases] so home/all-bookings
  /// still match when API id and guest_date keys differ.
  Future<void> markCancelled(
    String bookingKey, {
    Iterable<String> aliases = const [],
  }) async {
    final all = _loadAll();
    final keys = <String>{
      bookingKey.trim(),
      ...aliases.map((k) => k.trim()),
    }.where((k) => k.isNotEmpty);
    final now = DateTime.now().toIso8601String();
    for (final k in keys) {
      final existing = Map<String, dynamic>.from(all[k] ?? {});
      existing['status'] = 'cancelled';
      existing['cancelledAt'] = now;
      all[k] = existing;
    }
    await _saveAll(all);
  }

  Future<void> clearCancelled(
    String bookingKey, {
    Iterable<String> aliases = const [],
  }) async {
    final all = _loadAll();
    final keys = <String>{
      bookingKey.trim(),
      ...aliases.map((k) => k.trim()),
    }.where((k) => k.isNotEmpty);
    for (final k in keys) {
      final existing = Map<String, dynamic>.from(all[k] ?? {});
      existing.remove('status');
      existing.remove('cancelledAt');
      if (existing.isEmpty) {
        all.remove(k);
      } else {
        all[k] = existing;
      }
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
