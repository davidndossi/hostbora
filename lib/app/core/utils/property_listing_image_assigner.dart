/// Picks a stable default listing image from bundled `images/LR-{1..14}.*` assets.
abstract class PropertyListingImageAssigner {
  PropertyListingImageAssigner._();

  static const int imageCount = 14;

  /// Asset paths under [images/] (must match files in pubspec assets).
  static const List<String> lrAssetPaths = [
    'images/LR-1.png',
    'images/LR-2.jpeg',
    'images/LR-3.jpeg',
    'images/LR-4.jpg',
    'images/LR-5.jpg',
    'images/LR-6.png',
    'images/LR-7.png',
    'images/LR-8.png',
    'images/LR-9.jpg',
    'images/LR-10.jpg',
    'images/LR-11.jpg',
    'images/LR-12.jpg',
    'images/LR-13.jpg',
    'images/LR-14.jpg',
  ];

  /// Deterministic index in `1..14` from a stable property seed (ref, local id, name).
  static int indexForSeed(String seed) {
    final s = seed.trim();
    if (s.isEmpty) return 1;
    var hash = 0;
    for (final unit in s.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % imageCount) + 1;
  }

  /// Returns `images/LR-n.ext` for [index] in `1..14`.
  static String assetPathForIndex(int index) {
    final i = index.clamp(1, imageCount);
    return lrAssetPaths[i - 1];
  }

  /// Assigns an LR asset path for a new or existing property (stable per seed).
  static String assignForProperty({
    required String propertyRef,
    int? localPropertyId,
    String? propertyName,
  }) {
    final seed = _seedFor(
      propertyRef: propertyRef,
      localPropertyId: localPropertyId,
      propertyName: propertyName,
    );
    return assetPathForIndex(indexForSeed(seed));
  }

  static String _seedFor({
    required String propertyRef,
    int? localPropertyId,
    String? propertyName,
  }) {
    final ref = propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    if (localPropertyId != null) return 'local_$localPropertyId';
    return propertyName?.trim() ?? '';
  }

  /// Uses [storedPath] when set; otherwise assigns from LR pool.
  static String resolveDisplayPath({
    String? storedPath,
    required String propertyRef,
    int? localPropertyId,
    String? propertyName,
  }) {
    final stored = storedPath?.trim() ?? '';
    if (stored.isNotEmpty) return stored;
    return assignForProperty(
      propertyRef: propertyRef,
      localPropertyId: localPropertyId,
      propertyName: propertyName,
    );
  }

  static bool isBundledAssetPath(String path) {
    final p = path.trim();
    return p.startsWith('images/LR-');
  }

  static bool isNetworkPath(String path) {
    final p = path.trim().toLowerCase();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  /// User-selected file path wins; else keep [existingStoredPath]; else assign LR asset.
  static String coverPathForSave({
    required String propertyRef,
    String? userSelectedPath,
    String? existingStoredPath,
    int? localPropertyId,
    String? propertyName,
  }) {
    final user = userSelectedPath?.trim() ?? '';
    if (user.isNotEmpty) return user;
    final existing = existingStoredPath?.trim() ?? '';
    if (existing.isNotEmpty) return existing;
    return assignForProperty(
      propertyRef: propertyRef,
      localPropertyId: localPropertyId,
      propertyName: propertyName,
    );
  }
}
