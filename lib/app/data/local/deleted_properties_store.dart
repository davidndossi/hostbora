import 'package:get_storage/get_storage.dart';

/// Refs for properties the user deleted on-device.
///
/// Prevents remote sync / listing merge from immediately resurrecting a row
/// that was removed from the property list.
class DeletedPropertiesStore {
  DeletedPropertiesStore() : _box = GetStorage();

  static const _key = 'deleted_property_refs';

  final GetStorage _box;

  Set<String> load() {
    final raw = _box.read(_key);
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  bool contains(String ref) {
    final key = ref.trim();
    if (key.isEmpty) return false;
    return load().contains(key);
  }

  Future<void> markDeleted(Iterable<String> refs) async {
    final all = load();
    var changed = false;
    for (final r in refs) {
      final key = r.trim();
      if (key.isEmpty) continue;
      if (all.add(key)) changed = true;
    }
    if (changed) await _box.write(_key, all.toList());
  }
}
