import 'dart:convert';

import 'preference/preference_manager.dart';

/// Persists feedback when the device cannot open a mail client.
class FeedbackPendingStore {
  static const _key = 'pending_feedback_entries';

  FeedbackPendingStore(this._prefs);

  final PreferenceManager _prefs;

  Future<void> saveEntry(Map<String, dynamic> entry) async {
    final raw = await _prefs.getString(_key, defaultValue: '[]');
    final list = <dynamic>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) list.addAll(decoded);
    } catch (_) {}
    list.add({
      ...entry,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(_key, jsonEncode(list));
  }
}
