import 'dart:convert';

import 'package:get/get.dart';

import '../../data/local/db/rent_staff_local_data_source.dart';
import '../../data/local/preference/preference_manager.dart';

/// True when the API is rejecting sign-in because the phone has no account.
bool isMissingAccountError(String? raw) {
  final lower = (raw ?? '').toLowerCase();
  return lower.contains('no account') ||
      lower.contains('account not found') ||
      lower.contains('user not found') ||
      lower.contains('does not exist') ||
      lower.contains('no longer exist') ||
      lower.contains('account deleted') ||
      lower.contains('been deleted') ||
      lower.contains('was deleted') ||
      lower.contains('deactivated') ||
      lower.contains('akaunti haipo') ||
      lower.contains('haijapatikana');
}

String missingAccountLoginMessage() {
  final isSw = Get.locale?.languageCode == 'sw';
  return isSw
      ? 'Akaunti hii haipo tena. Tafadhali fungua akaunti mpya.'
      : 'This account no longer exists. Please create a new account.';
}

/// True when the API says this sign-in belongs to a removed or deactivated staff account.
bool isRemovedStaffError(String? raw) {
  final lower = (raw ?? '').toLowerCase();
  if (lower.isEmpty) return false;
  final aboutStaff = lower.contains('staff') || lower.contains('mfanyakazi');
  final denied = lower.contains('remov') ||
      lower.contains('deactivat') ||
      lower.contains('disabled') ||
      lower.contains('inactive') ||
      lower.contains('deleted') ||
      lower.contains('not found') ||
      lower.contains('ondole') ||
      lower.contains('no longer') ||
      lower.contains('not authorized') ||
      lower.contains('unauthor') ||
      lower.contains('revok') ||
      lower.contains('haipo');
  if (aboutStaff && denied) return true;
  return lower.contains('staff account') ||
      lower.contains('akaunti ya mfanyakazi');
}

String removedStaffLoginMessage() {
  final isSw = Get.locale?.languageCode == 'sw';
  return isSw
      ? 'Akaunti hii ya mfanyakazi imeondolewa na haina ruhusa tena. Wasiliana na mmiliki wa mali ikiwa unahitaji ufikiaji.'
      : 'This staff account has been removed and no longer has access. Contact the property owner if you still need access.';
}

/// Phones whose staff login was removed on this device.
///
/// The OTP request for those numbers often comes back as a generic send
/// failure. Remembering the phone lets sign-in explain that access was removed.
class RemovedStaffPhones {
  RemovedStaffPhones._();

  static const _key = 'removed_staff_phones';

  static PreferenceManager? get _prefs {
    if (!Get.isRegistered<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    )) {
      return null;
    }
    return Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
  }

  static Future<void> remember(String phone) async {
    final key = _phoneKey(phone);
    if (key.isEmpty) return;
    final prefs = _prefs;
    if (prefs == null) return;
    final all = await _read(prefs);
    if (all.contains(key)) return;
    all.add(key);
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<void> forget(String phone) async {
    final key = _phoneKey(phone);
    if (key.isEmpty) return;
    final prefs = _prefs;
    if (prefs == null) return;
    final all = await _read(prefs);
    if (!all.remove(key)) return;
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<bool> contains(String phone) async {
    final key = _phoneKey(phone);
    if (key.isEmpty) return false;
    final prefs = _prefs;
    if (prefs == null) return false;
    return (await _read(prefs)).contains(key);
  }

  static String _phoneKey(String raw) {
    final normalized = RentStaffLocalDataSource.normalizePhone(raw);
    if (normalized != null && normalized.isNotEmpty) return normalized;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) return digits.substring(digits.length - 9);
    return '';
  }

  static Future<Set<String>> _read(PreferenceManager prefs) async {
    final raw = await prefs.getString(_key, defaultValue: '');
    if (raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
      }
    } catch (_) {}
    return <String>{};
  }
}
