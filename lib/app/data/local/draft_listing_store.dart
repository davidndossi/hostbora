import 'package:get_storage/get_storage.dart';

/// Persists a single listing draft (form state) so the user can resume later.
class DraftListingStore {
  DraftListingStore() : _box = GetStorage();

  static const _key = 'listing_draft';

  final GetStorage _box;

  /// Saves the current draft. Overwrites any existing draft.
  Future<void> save({
    required Map<String, dynamic> listingJson,
    required Map<String, List<String>> roomPhotoPaths,
    String? coverPhotoPath,
    int currentStep = 1,
  }) async {
    final pathsJson = <String, dynamic>{};
    for (final e in roomPhotoPaths.entries) {
      pathsJson[e.key] = e.value;
    }
    final data = <String, dynamic>{
      'listing': listingJson,
      'roomPhotoPaths': pathsJson,
      'currentStep': currentStep,
      'savedAt': DateTime.now().toIso8601String(),
    };
    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      data['coverPhotoPath'] = coverPhotoPath;
    }
    await _box.write(_key, data);
  }

  /// Returns the saved draft, or null if none.
  Map<String, dynamic>? load() {
    final raw = _box.read(_key);
    if (raw == null || raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Removes the saved draft.
  Future<void> clear() async {
    await _box.remove(_key);
  }

  bool get hasDraft => load() != null;
}
