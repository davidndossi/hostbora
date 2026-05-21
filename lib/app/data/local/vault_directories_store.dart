import 'package:get_storage/get_storage.dart';

/// Default vault folder definitions (backend has no directory-list API).
class VaultDirectoryDef {
  const VaultDirectoryDef({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    this.isLocked = false,
  });

  final String id;
  final String nameEn;
  final String nameSw;
  final bool isLocked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameSw': nameSw,
        'isLocked': isLocked,
      };

  factory VaultDirectoryDef.fromJson(Map<String, dynamic> json) {
    return VaultDirectoryDef(
      id: json['id']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      nameSw: json['nameSw']?.toString() ?? '',
      isLocked: json['isLocked'] == true,
    );
  }
}

/// Persists vault directory list; seeds defaults on first run.
class VaultDirectoriesStore {
  VaultDirectoriesStore() : _box = GetStorage();

  static const _key = 'vault_directories_v1';

  static const List<VaultDirectoryDef> defaultDirectories = [
    VaultDirectoryDef(
      id: 'legal',
      nameEn: 'Legal Documents',
      nameSw: 'Nyaraka za Kisheria',
    ),
    VaultDirectoryDef(
      id: 'tax',
      nameEn: 'Tax Records',
      nameSw: 'Kumbukumbu za Kodi',
    ),
    VaultDirectoryDef(
      id: 'manuals',
      nameEn: 'Property Manuals',
      nameSw: 'Miongozo ya Mali',
    ),
    VaultDirectoryDef(
      id: 'guest_ids',
      nameEn: 'Guest IDs',
      nameSw: 'Vitambulisho vya Wageni',
      isLocked: true,
    ),
    VaultDirectoryDef(
      id: 'maintenance',
      nameEn: 'Maintenance',
      nameSw: 'Matengenezo',
    ),
    VaultDirectoryDef(
      id: 'photos',
      nameEn: 'Property Photos',
      nameSw: 'Picha za Mali',
    ),
  ];

  final GetStorage _box;

  List<VaultDirectoryDef> loadDirectories() {
    final raw = _box.read(_key);
    if (raw is List && raw.isNotEmpty) {
      final parsed = raw
          .whereType<Map>()
          .map((e) => VaultDirectoryDef.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.id.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return List<VaultDirectoryDef>.from(defaultDirectories);
  }

  Future<void> ensureDefaults() async {
    if (_box.read(_key) == null) {
      await _box.write(
        _key,
        defaultDirectories.map((e) => e.toJson()).toList(),
      );
    }
  }

  /// Merges API-provided directories (id + name) with stored list.
  Future<void> mergeFromApi(List<VaultDirectoryDef> fromApi) async {
    if (fromApi.isEmpty) return;
    final existing = loadDirectories();
    final byId = {for (final d in existing) d.id: d};
    for (final apiDir in fromApi) {
      byId[apiDir.id] = apiDir;
    }
    await _box.write(_key, byId.values.map((e) => e.toJson()).toList());
  }
}
