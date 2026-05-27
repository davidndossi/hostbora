import 'dart:convert';
import 'dart:math';

import 'package:get_storage/get_storage.dart';

/// Persisted guest door PIN for a booking or custom access entry.
class StoredGuestAccessCode {
  const StoredGuestAccessCode({
    required this.id,
    required this.guestName,
    required this.pin,
    required this.checkInIso,
    required this.checkOutIso,
    this.revoked = false,
    this.isCustom = false,
    this.createdAtMs,
  });

  final String id;
  final String guestName;
  final String pin;
  final String checkInIso;
  final String checkOutIso;
  final bool revoked;
  final bool isCustom;
  final int? createdAtMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'guestName': guestName,
        'pin': pin,
        'checkInIso': checkInIso,
        'checkOutIso': checkOutIso,
        'revoked': revoked,
        'isCustom': isCustom,
        if (createdAtMs != null) 'createdAtMs': createdAtMs,
      };

  factory StoredGuestAccessCode.fromJson(Map<String, dynamic> json) {
    return StoredGuestAccessCode(
      id: json['id']?.toString() ?? '',
      guestName: json['guestName']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      checkInIso: json['checkInIso']?.toString() ?? '',
      checkOutIso: json['checkOutIso']?.toString() ?? '',
      revoked: json['revoked'] == true,
      isCustom: json['isCustom'] == true,
      createdAtMs: json['createdAtMs'] is int
          ? json['createdAtMs'] as int
          : int.tryParse(json['createdAtMs']?.toString() ?? ''),
    );
  }

  StoredGuestAccessCode copyWith({
    String? guestName,
    String? pin,
    String? checkInIso,
    String? checkOutIso,
    bool? revoked,
  }) {
    return StoredGuestAccessCode(
      id: id,
      guestName: guestName ?? this.guestName,
      pin: pin ?? this.pin,
      checkInIso: checkInIso ?? this.checkInIso,
      checkOutIso: checkOutIso ?? this.checkOutIso,
      revoked: revoked ?? this.revoked,
      isCustom: isCustom,
      createdAtMs: createdAtMs,
    );
  }
}

/// Offline-first PIN storage keyed by booking id or custom access id.
class GuestAccessCodesStore {
  GuestAccessCodesStore() : _box = GetStorage();

  static const _key = 'guest_access_codes';

  final GetStorage _box;
  final _rng = Random();

  Map<String, StoredGuestAccessCode> _loadAll() {
    final raw = _box.read(_key);
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          StoredGuestAccessCode.fromJson(
            v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
          ),
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
              StoredGuestAccessCode.fromJson(
                v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
              ),
            ),
          );
        }
      } catch (_) {}
    }
    return {};
  }

  Future<void> _saveAll(Map<String, StoredGuestAccessCode> all) async {
    await _box.write(
      _key,
      all.map((k, v) => MapEntry(k, v.toJson())),
    );
  }

  StoredGuestAccessCode? get(String id) => _loadAll()[id];

  /// Returns existing PIN or creates and persists a new 6-digit code.
  Future<String> pinForBooking({
    required String bookingKey,
    required String guestName,
    required String checkInIso,
    required String checkOutIso,
  }) async {
    final all = _loadAll();
    final existing = all[bookingKey];
    if (existing != null &&
        !existing.revoked &&
        existing.pin.length >= 4) {
      return existing.pin;
    }
    final pin = _newPin();
    all[bookingKey] = StoredGuestAccessCode(
      id: bookingKey,
      guestName: guestName,
      pin: pin,
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveAll(all);
    return pin;
  }

  Future<StoredGuestAccessCode> saveCustom({
    required String guestName,
    required String checkInIso,
    required String checkOutIso,
    String? pin,
  }) async {
    final all = _loadAll();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final entry = StoredGuestAccessCode(
      id: id,
      guestName: guestName.trim(),
      pin: pin?.trim().isNotEmpty == true ? pin!.trim() : _newPin(),
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      isCustom: true,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    all[id] = entry;
    await _saveAll(all);
    return entry;
  }

  Future<void> revoke(String id) async {
    final all = _loadAll();
    final existing = all[id];
    if (existing == null) return;
    all[id] = existing.copyWith(revoked: true);
    await _saveAll(all);
  }

  Future<void> updatePin(String id, String newPin) async {
    final all = _loadAll();
    final existing = all[id];
    if (existing == null) return;
    all[id] = existing.copyWith(pin: newPin.trim());
    await _saveAll(all);
  }

  List<StoredGuestAccessCode> listActiveCustom() {
    return _loadAll().values
        .where((e) => e.isCustom && !e.revoked)
        .toList();
  }

  String _newPin() {
    return (100000 + _rng.nextInt(900000)).toString();
  }
}
