import 'package:get_storage/get_storage.dart';

/// Persists expense requests (and optional receipt path) when offline. Sync when back online.
class PendingExpensesStore {
  PendingExpensesStore() : _box = GetStorage();

  static const _key = 'pending_expenses';

  final GetStorage _box;

  List<Map<String, dynamic>> load() {
    final raw = _box.read(_key);
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m['expenseDate'] != null && m['vendor'] != null)
          .toList();
    }
    return [];
  }

  Future<void> add(Map<String, dynamic> requestJson, [String? receiptFilePath]) async {
    final list = load();
    list.add({
      ...requestJson,
      if (receiptFilePath != null && receiptFilePath.isNotEmpty) 'receiptFilePath': receiptFilePath,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _box.write(_key, list);
  }

  Future<void> save(List<Map<String, dynamic>> list) async {
    await _box.write(_key, list);
  }

  int get count => load().length;
}
