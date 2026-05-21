import 'package:get_storage/get_storage.dart';

/// Persists design moodboards and their saved images locally (GetStorage).
class DesignMoodboardsStore {
  DesignMoodboardsStore() : _box = GetStorage();

  static const _boardsKey = 'design_moodboards_v1';

  final GetStorage _box;

  List<StoredMoodboard> loadBoards() {
    final raw = _box.read(_boardsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => StoredMoodboard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveBoards(List<StoredMoodboard> boards) async {
    await _box.write(_boardsKey, boards.map((e) => e.toJson()).toList());
  }

  Future<StoredMoodboard> upsertBoard(StoredMoodboard board) async {
    final boards = loadBoards();
    final idx = boards.indexWhere((b) => b.id == board.id);
    if (idx >= 0) {
      boards[idx] = board;
    } else {
      boards.add(board);
    }
    await saveBoards(boards);
    return board;
  }

  Future<void> deleteBoard(String id) async {
    final boards = loadBoards()..removeWhere((b) => b.id == id);
    await saveBoards(boards);
  }

  StoredMoodboard? findById(String id) {
    for (final b in loadBoards()) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<bool> seedDefaultsIfEmpty() async {
    if (loadBoards().isNotEmpty) return false;
    final now = DateTime.now();
    await saveBoards([
      StoredMoodboard(
        id: 'seed-1',
        title: 'Mediterranean Vibes',
        coverPath: 'images/mediterranean_vibes.jpg',
        showAiBadge: true,
        aiConcept: true,
        materials: false,
        createdAt: now.subtract(const Duration(days: 2)),
        items: const [
          StoredMoodboardItem(
            id: 'c1',
            name: 'Main Living Area',
            imagePath: 'images/main_living_area.png',
            fromAi: true,
          ),
          StoredMoodboardItem(
            id: 'c2',
            name: 'Textile Details',
            imagePath: 'images/textile_details.jpg',
            fromAi: false,
          ),
        ],
        palette: _defaultPalette,
        texturePaths: const [
          'images/chair.jpg',
          'images/basket.jpg',
          'images/pottery.jpg',
        ],
      ),
      StoredMoodboard(
        id: 'seed-2',
        title: 'Victorian Suite',
        coverPath: 'images/victorian_suite.jpg',
        showAiBadge: false,
        aiConcept: false,
        materials: true,
        createdAt: now.subtract(const Duration(days: 5)),
        items: const [],
        palette: _defaultPalette,
        texturePaths: const [],
      ),
      StoredMoodboard(
        id: 'seed-3',
        title: 'Modern Minimalist',
        coverPath: 'images/modern_minimalist.jpg',
        showAiBadge: true,
        aiConcept: true,
        materials: false,
        createdAt: now.subtract(const Duration(days: 1)),
        items: const [],
        palette: _defaultPalette,
        texturePaths: const [],
      ),
    ]);
    return true;
  }
}

const _defaultPalette = [
  StoredPaletteSwatch(hex: '#E2725B', label: 'Terracotta'),
  StoredPaletteSwatch(hex: '#F4A460', label: 'Sand'),
  StoredPaletteSwatch(hex: '#0D6D6D', label: 'Teal'),
  StoredPaletteSwatch(hex: '#D2B48C', label: 'Tan'),
  StoredPaletteSwatch(hex: '#F5F5F5', label: 'Off-white'),
];

class StoredPaletteSwatch {
  const StoredPaletteSwatch({required this.hex, this.label});

  final String hex;
  final String? label;

  Map<String, dynamic> toJson() => {
        'hex': hex,
        if (label != null) 'label': label,
      };

  factory StoredPaletteSwatch.fromJson(Map<String, dynamic> json) {
    return StoredPaletteSwatch(
      hex: json['hex'] as String? ?? '#000000',
      label: json['label'] as String?,
    );
  }
}

class StoredMoodboardItem {
  const StoredMoodboardItem({
    required this.id,
    required this.name,
    required this.imagePath,
    this.fromAi = false,
  });

  final String id;
  final String name;
  /// Asset path, local file path, or remote URL.
  final String imagePath;
  final bool fromAi;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'fromAi': fromAi,
      };

  factory StoredMoodboardItem.fromJson(Map<String, dynamic> json) {
    return StoredMoodboardItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Concept',
      imagePath: json['imagePath'] as String? ?? '',
      fromAi: json['fromAi'] as bool? ?? false,
    );
  }
}

class StoredMoodboard {
  StoredMoodboard({
    required this.id,
    required this.title,
    this.coverPath,
    this.showAiBadge = false,
    this.aiConcept = false,
    this.materials = false,
    required this.createdAt,
    this.items = const [],
    this.palette = _defaultPalette,
    this.texturePaths = const [],
    this.selectedPaletteIndex = 2,
  });

  final String id;
  final String title;
  final String? coverPath;
  final bool showAiBadge;
  final bool aiConcept;
  final bool materials;
  final DateTime createdAt;
  final List<StoredMoodboardItem> items;
  final List<StoredPaletteSwatch> palette;
  final List<String> texturePaths;
  final int selectedPaletteIndex;

  int get savedCount => items.length + texturePaths.length;

  String? get displayCover =>
      coverPath ??
      (items.isNotEmpty ? items.first.imagePath : null);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (coverPath != null) 'coverPath': coverPath,
        'showAiBadge': showAiBadge,
        'aiConcept': aiConcept,
        'materials': materials,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'palette': palette.map((e) => e.toJson()).toList(),
        'texturePaths': texturePaths,
        'selectedPaletteIndex': selectedPaletteIndex,
      };

  factory StoredMoodboard.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final paletteRaw = json['palette'];
    final texturesRaw = json['texturePaths'];
    return StoredMoodboard(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Moodboard',
      coverPath: json['coverPath'] as String?,
      showAiBadge: json['showAiBadge'] as bool? ?? false,
      aiConcept: json['aiConcept'] as bool? ?? false,
      materials: json['materials'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map((e) =>
                  StoredMoodboardItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      palette: paletteRaw is List && paletteRaw.isNotEmpty
          ? paletteRaw
              .whereType<Map>()
              .map((e) =>
                  StoredPaletteSwatch.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : _defaultPalette,
      texturePaths: texturesRaw is List
          ? texturesRaw.map((e) => e.toString()).toList()
          : const [],
      selectedPaletteIndex: json['selectedPaletteIndex'] as int? ?? 2,
    );
  }

  StoredMoodboard copyWith({
    String? title,
    String? coverPath,
    bool? showAiBadge,
    bool? aiConcept,
    bool? materials,
    List<StoredMoodboardItem>? items,
    List<String>? texturePaths,
    int? selectedPaletteIndex,
  }) {
    return StoredMoodboard(
      id: id,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      showAiBadge: showAiBadge ?? this.showAiBadge,
      aiConcept: aiConcept ?? this.aiConcept,
      materials: materials ?? this.materials,
      createdAt: createdAt,
      items: items ?? this.items,
      palette: palette,
      texturePaths: texturePaths ?? this.texturePaths,
      selectedPaletteIndex: selectedPaletteIndex ?? this.selectedPaletteIndex,
    );
  }
}
