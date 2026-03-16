import 'package:get_storage/get_storage.dart';

/// Persists listing + room photo paths when offline. Sync when back online.
class PendingListingsStore {
  PendingListingsStore() : _box = GetStorage();

  static const _key = 'pending_listings';

  final GetStorage _box;

  List<Map<String, dynamic>> load() {
    final raw = _box.read(_key);
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m['listing'] is Map)
          .toList();
    }
    return [];
  }

  Future<void> add(
    Map<String, dynamic> listingJson,
    Map<String, List<String>> roomPhotoPaths, {
    String? coverPhotoPath,
  }) async {
    final list = load();
    final pathsJson = <String, dynamic>{};
    for (final e in roomPhotoPaths.entries) {
      pathsJson[e.key] = e.value;
    }
    final entry = <String, dynamic>{
      'listing': listingJson,
      'roomPhotoPaths': pathsJson,
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      entry['coverPhotoPath'] = coverPhotoPath;
    }
    list.add(entry);
    await _box.write(_key, list);
  }

  Future<void> save(List<Map<String, dynamic>> list) async {
    await _box.write(_key, list);
  }

  int get count => load().length;
}
