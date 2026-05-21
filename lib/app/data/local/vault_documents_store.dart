import 'package:get_storage/get_storage.dart';

/// Locally persisted vault documents (no upload API on backend).
class VaultDocumentsStore {
  VaultDocumentsStore() : _box = GetStorage();

  static const _key = 'vault_documents_v1';

  final GetStorage _box;

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
    return doc;
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
