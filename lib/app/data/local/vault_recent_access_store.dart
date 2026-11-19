import 'package:get_storage/get_storage.dart';

enum VaultRecentTargetType { document, directory }

class VaultRecentAccessEntry {
  const VaultRecentAccessEntry({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.displayName,
    required this.lastAccessedAtMs,
    this.directoryId,
    this.localPath,
  });

  final String id;
  final VaultRecentTargetType targetType;
  final String targetId;
  final String displayName;
  final int lastAccessedAtMs;
  final String? directoryId;
  final String? localPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType.name,
        'targetId': targetId,
        'displayName': displayName,
        'lastAccessedAtMs': lastAccessedAtMs,
        if (directoryId != null) 'directoryId': directoryId,
        if (localPath != null) 'localPath': localPath,
      };

  factory VaultRecentAccessEntry.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['targetType']?.toString() ?? 'document';
    return VaultRecentAccessEntry(
      id: json['id']?.toString() ?? '',
      targetType: typeRaw == 'directory'
          ? VaultRecentTargetType.directory
          : VaultRecentTargetType.document,
      targetId: json['targetId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      lastAccessedAtMs: json['lastAccessedAtMs'] is int
          ? json['lastAccessedAtMs'] as int
          : int.tryParse(json['lastAccessedAtMs']?.toString() ?? '') ??
              0,
      directoryId: json['directoryId']?.toString(),
      localPath: json['localPath']?.toString(),
    );
  }
}

/// Tracks recently opened vault directories and documents (top 5 on home).
class VaultRecentAccessStore {
  VaultRecentAccessStore() : _box = GetStorage();

  static const _key = 'vault_recent_access_v1';
  static const homeLimit = 5;

  final GetStorage _box;

  List<VaultRecentAccessEntry> loadAll() {
    final raw = _box.read(_key);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => VaultRecentAccessEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.displayName.isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastAccessedAtMs.compareTo(a.lastAccessedAtMs));
  }

  List<VaultRecentAccessEntry> loadTop({int limit = homeLimit}) {
    return loadAll().take(limit).toList();
  }

  Future<void> recordDirectory({
    required String directoryId,
    required String displayName,
  }) async {
    await _upsert(
      targetType: VaultRecentTargetType.directory,
      targetId: directoryId,
      displayName: displayName,
      directoryId: directoryId,
    );
  }

  /// Removes recent document rows matching any [names] or [localPath].
  Future<List<VaultRecentAccessEntry>> removeDocumentsNamed(
    String displayName, {
    String? localPath,
    Set<String> alsoNames = const {},
  }) async {
    final names = <String>{
      displayName.trim().toLowerCase(),
      ...alsoNames.map((name) => name.trim().toLowerCase()),
    }..removeWhere((name) => name.isEmpty);
    final path = localPath?.trim() ?? '';
    if (names.isEmpty && path.isEmpty) return [];
    final all = loadAll();
    final removed = all.where((entry) {
      if (entry.targetType != VaultRecentTargetType.document) return false;
      if (path.isNotEmpty && (entry.localPath?.trim() ?? '') == path) {
        return true;
      }
      return names.contains(entry.displayName.trim().toLowerCase());
    }).toList();
    if (removed.isEmpty) return [];
    final removedIds = removed.map((entry) => entry.id).toSet();
    final kept = all.where((entry) => !removedIds.contains(entry.id)).toList();
    await _box.write(_key, kept.map((entry) => entry.toJson()).toList());
    return removed;
  }

  Future<void> removeByIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    final all = loadAll();
    final kept = all.where((entry) => !ids.contains(entry.id)).toList();
    if (kept.length == all.length) return;
    await _box.write(_key, kept.map((entry) => entry.toJson()).toList());
  }

  Future<void> renameDocumentsNamed(String fromName, String toName) async {
    final target = fromName.trim().toLowerCase();
    final next = toName.trim();
    if (target.isEmpty || next.isEmpty || target == next.toLowerCase()) return;
    final all = loadAll();
    var changed = false;
    final updated = all.map((entry) {
      if (entry.targetType != VaultRecentTargetType.document) return entry;
      if (entry.displayName.trim().toLowerCase() != target) return entry;
      changed = true;
      return VaultRecentAccessEntry(
        id: entry.id,
        targetType: entry.targetType,
        targetId: entry.targetId,
        displayName: next,
        lastAccessedAtMs: entry.lastAccessedAtMs,
        directoryId: entry.directoryId,
        localPath: entry.localPath,
      );
    }).toList();
    if (!changed) return;
    await _box.write(_key, updated.map((e) => e.toJson()).toList());
  }

  Future<void> recordDocument({
    required String documentId,
    required String displayName,
    String? directoryId,
    String? localPath,
  }) async {
    await _upsert(
      targetType: VaultRecentTargetType.document,
      targetId: documentId,
      displayName: displayName,
      directoryId: directoryId,
      localPath: localPath,
    );
  }

  Future<void> _upsert({
    required VaultRecentTargetType targetType,
    required String targetId,
    required String displayName,
    String? directoryId,
    String? localPath,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final all = loadAll();
    final compositeKey = '${targetType.name}:$targetId';
    all.removeWhere((e) => '${e.targetType.name}:${e.targetId}' == compositeKey);
    all.insert(
      0,
      VaultRecentAccessEntry(
        id: compositeKey,
        targetType: targetType,
        targetId: targetId,
        displayName: displayName,
        lastAccessedAtMs: now,
        directoryId: directoryId,
        localPath: localPath,
      ),
    );
    await _box.write(_key, all.map((e) => e.toJson()).toList());
  }
}
