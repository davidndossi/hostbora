import 'package:get_storage/get_storage.dart';

/// Locally persisted vault documents (no upload API on backend).
class VaultDocumentsStore {
  VaultDocumentsStore() : _box = GetStorage();

  static const _key = 'vault_documents_v1';
  static const _removedKey = 'vault_documents_removed_v1';
  static const _renameKey = 'vault_document_renames_v1';

  final GetStorage _box;

  /// Lowercased file names the user removed from the list.
  /// Remote refetches must not put these back until the file is saved again.
  Set<String> removedNames() {
    final raw = _box.read(_removedKey);
    if (raw is! List) return {};
    return raw.map((e) => e.toString().trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
  }

  Future<void> hideName(String fileName) async {
    final key = fileName.trim().toLowerCase();
    if (key.isEmpty) return;
    final names = removedNames()..add(key);
    await _box.write(_removedKey, names.toList());
  }

  Future<void> unhideName(String fileName) async {
    final key = fileName.trim().toLowerCase();
    if (key.isEmpty) return;
    final names = removedNames()..remove(key);
    await _box.write(_removedKey, names.toList());
  }

  Map<String, String> _renameMap() {
    final raw = _box.read(_renameKey);
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  /// Applies a saved rename, including a later rename of the same document.
  String resolveDisplayName(String raw) {
    var name = raw.trim();
    if (name.isEmpty) return name;
    final map = _renameMap();
    final seen = <String>{};
    while (seen.add(name.toLowerCase())) {
      final next = map[name.toLowerCase()]?.trim();
      if (next == null || next.isEmpty) return name;
      name = next;
    }
    return name;
  }

  /// Every stored name that currently displays as [displayName], including the name itself.
  Set<String> namesResolvingTo(String displayName) {
    final target = displayName.trim().toLowerCase();
    if (target.isEmpty) return {};
    final names = <String>{target};
    for (final entry in _renameMap().entries) {
      final key = entry.key.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (resolveDisplayName(key).trim().toLowerCase() == target) {
        names.add(key);
        final value = entry.value.trim().toLowerCase();
        if (value.isNotEmpty) names.add(value);
      }
    }
    return names;
  }

  /// Remembers [toName] as the display name for [fromName] and updates stored files.
  Future<void> renameDisplayName({
    required String fromName,
    required String toName,
  }) async {
    final from = fromName.trim();
    final to = toName.trim();
    if (from.isEmpty || to.isEmpty) return;
    if (from.toLowerCase() == to.toLowerCase()) return;

    final map = _renameMap();
    for (final key in map.keys.toList()) {
      if ((map[key] ?? '').trim().toLowerCase() == from.toLowerCase()) {
        map[key] = to;
      }
    }
    map[from.toLowerCase()] = to;
    map.remove(to.toLowerCase());
    await _box.write(_renameKey, map);

    final all = loadAll();
    var changed = false;
    final updated = all.map((doc) {
      if (doc.fileName.trim().toLowerCase() != from.toLowerCase()) return doc;
      changed = true;
      return StoredVaultDocument(
        id: doc.id,
        directoryId: doc.directoryId,
        fileName: to,
        localPath: doc.localPath,
        createdAt: doc.createdAt,
        synced: doc.synced,
      );
    }).toList();
    if (changed) {
      await _box.write(_key, updated.map((e) => e.toJson()).toList());
    }
  }

  List<StoredVaultDocument> loadAll() {
    final raw = _box.read(_key);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => StoredVaultDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<StoredVaultDocument> loadForDirectory(String directoryId) {
    final all = loadAll();
    if (directoryId == 'all') return all;
    return all.where((d) => d.directoryId == directoryId).toList();
  }

  Future<StoredVaultDocument> add(StoredVaultDocument doc) async {
    final all = loadAll()..add(doc);
    await _box.write(_key, all.map((e) => e.toJson()).toList());
    await unhideName(doc.fileName);
    return doc;
  }

  /// Drops every stored document with this file name. Returns what was removed
  /// so the caller can restore it if the user undoes.
  Future<List<StoredVaultDocument>> removeByFileName(String fileName) async {
    final target = fileName.trim().toLowerCase();
    if (target.isEmpty) return [];
    final all = loadAll();
    final removed = all
        .where((d) => d.fileName.trim().toLowerCase() == target)
        .toList();
    if (removed.isEmpty) return [];
    final kept =
        all.where((d) => d.fileName.trim().toLowerCase() != target).toList();
    await _box.write(_key, kept.map((e) => e.toJson()).toList());
    return removed;
  }
}

class StoredVaultDocument {
  const StoredVaultDocument({
    required this.id,
    required this.directoryId,
    required this.fileName,
    required this.localPath,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String directoryId;
  final String fileName;
  final String localPath;
  final DateTime createdAt;
  final bool synced;

  Map<String, dynamic> toJson() => {
        'id': id,
        'directoryId': directoryId,
        'fileName': fileName,
        'localPath': localPath,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory StoredVaultDocument.fromJson(Map<String, dynamic> json) {
    return StoredVaultDocument(
      id: json['id'] as String? ?? '',
      directoryId: json['directoryId'] as String? ?? 'general',
      fileName: json['fileName'] as String? ?? 'document.jpg',
      localPath: json['localPath'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      synced: json['synced'] as bool? ?? false,
    );
  }
}
