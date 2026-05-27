import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../vault_route_args.dart';

enum DocumentFilter { all, urgent, verified, more }

enum DocumentFileType { pdf, xlsx, image }

class DocumentItem {
  final String name;
  final String size;
  final bool synced;
  final DocumentFileType fileType;

  const DocumentItem({
    required this.name,
    required this.size,
    this.synced = true,
    required this.fileType,
  });
}

class DocumentsController extends BaseController {
  DocumentsController({
    AppRepository? repository,
    VaultDocumentsStore? vaultStore,
    VaultRecentAccessStore? recentStore,
  })  : _repository = repository ??
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _vaultStore = vaultStore ?? VaultDocumentsStore(),
        _recentStore = recentStore ?? VaultRecentAccessStore();

  final AppRepository _repository;
  final VaultDocumentsStore _vaultStore;
  final VaultRecentAccessStore _recentStore;

  String? directoryId;
  String? directoryName;

  final selectedFilter = DocumentFilter.all.obs;
  final documents = <DocumentItem>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = VaultRouteArgs.fromGetArguments();
    directoryId = args.directoryId;
    directoryName = args.directoryName;
    _recordDirectoryAccess();
    loadDocuments();
  }

  Future<void> _recordDirectoryAccess() async {
    final dirId = directoryId;
    if (dirId == null || dirId.isEmpty) return;
    final name = directoryName?.trim();
    if (name == null || name.isEmpty) return;
    await _recentStore.recordDirectory(
      directoryId: dirId,
      displayName: name,
    );
  }

  /// Fetches remote documents and merges locally saved vault scans.
  Future<void> loadDocuments() async {
    final dirId = directoryId ?? 'all';
    loading.value = true;
    try {
      final remote = await _fetchRemoteDocuments(dirId);
      final local = _localDocumentsFor(dirId);
      final seen = <String>{};
      final merged = <DocumentItem>[];
      for (final item in [...local, ...remote]) {
        final key = item.name.toLowerCase();
        if (seen.add(key)) merged.add(item);
      }
      documents.assignAll(merged);
    } catch (_) {
      documents.assignAll(_localDocumentsFor(dirId));
    } finally {
      loading.value = false;
    }
  }

  Future<List<DocumentItem>> _fetchRemoteDocuments(String dirId) async {
    try {
      final res = await _repository.getVaultDocuments(dirId);
      final data = res.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['documents'] is List) {
          rawList = data['documents'] as List;
        } else if (data['files'] is List) {
          rawList = data['files'] as List;
        } else if (data['content'] is List) {
          rawList = data['content'] as List;
        }
      }
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(_itemFromMap)
          .where((e) => e.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<DocumentItem> _localDocumentsFor(String dirId) {
    return _vaultStore
        .loadForDirectory(dirId)
        .where((d) => d.localPath.isNotEmpty && File(d.localPath).existsSync())
        .map(_itemFromStored)
        .toList();
  }

  static DocumentItem _itemFromStored(StoredVaultDocument d) {
    final file = File(d.localPath);
    final bytes = file.existsSync() ? file.lengthSync() : 0;
    return DocumentItem(
      name: d.fileName,
      size: _formatBytes(bytes),
      synced: d.synced,
      fileType: DocumentFileType.image,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static DocumentItem _itemFromMap(Map<String, dynamic> m) {
    final name = m['name']?.toString() ?? m['fileName']?.toString() ?? '';
    final size = m['size']?.toString() ?? m['sizeFormatted']?.toString() ?? '';
    final synced = m['synced'] as bool? ?? true;
    var ext = (m['extension']?.toString() ?? m['fileType']?.toString() ?? '').toLowerCase();
    if (ext.isEmpty && name.isNotEmpty) {
      final i = name.lastIndexOf('.');
      if (i >= 0 && i < name.length - 1) ext = name.substring(i + 1).toLowerCase();
    }
    DocumentFileType fileType = DocumentFileType.pdf;
    if (ext.contains('xls') || ext == 'xlsx') {
      fileType = DocumentFileType.xlsx;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      fileType = DocumentFileType.image;
    }
    return DocumentItem(name: name, size: size, synced: synced, fileType: fileType);
  }

  void goBack() => Get.back();

  void openSearch() {
    final query = ''.obs;
    final source = List<DocumentItem>.from(documents);

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (v) => query.value = v.trim().toLowerCase(),
                decoration: InputDecoration(
                  hintText: appLocalization.searchVaultDocuments,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: Obx(() {
                  final q = query.value;
                  final filtered = q.isEmpty
                      ? source
                      : source
                          .where((d) =>
                              d.name.toLowerCase().contains(q) ||
                              d.size.toLowerCase().contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(appLocalization.noDocuments),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      return ListTile(
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(item.size),
                        trailing: const Icon(Icons.more_vert),
                        onTap: () {
                          Get.back();
                          openDocumentOptions(item);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void selectFilter(DocumentFilter filter) {
    selectedFilter.value = filter;
  }

  void openDocumentOptions(DocumentItem item) {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () async {
                Get.back();
                await _openDocument(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(appLocalization.share),
              onTap: () async {
                Get.back();
                await _shareDocument(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove from list'),
              onTap: () {
                documents.remove(item);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(appLocalization.cancel),
              onTap: Get.back,
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> _openDocument(DocumentItem item) async {
    final path = _resolveLocalPath(item);
    if (path == null) {
      showErrorMessage('Document is not available offline yet.');
      return;
    }
    final opened = await OpenFile.open(path);
    if (opened.type == ResultType.noAppToOpen) {
      showErrorMessage('No app found to open this file.');
      return;
    }
    if (opened.type == ResultType.error) {
      showErrorMessage(opened.message.isNotEmpty
          ? opened.message
          : 'Could not open this document.');
      return;
    }
    await _recentStore.recordDocument(
      documentId: '${directoryId ?? 'all'}:${item.name.toLowerCase()}',
      displayName: item.name,
      directoryId: directoryId,
      localPath: path,
    );
  }

  Future<void> _shareDocument(DocumentItem item) async {
    final path = _resolveLocalPath(item);
    if (path == null) {
      showErrorMessage('Only offline documents can be shared right now.');
      return;
    }
    await _recentStore.recordDocument(
      documentId: '${directoryId ?? 'all'}:${item.name.toLowerCase()}',
      displayName: item.name,
      directoryId: directoryId,
      localPath: path,
    );
    await Share.shareXFiles([XFile(path)], subject: item.name, text: item.name);
  }

  String? _resolveLocalPath(DocumentItem item) {
    final dirId = directoryId ?? 'all';
    final candidates = _vaultStore.loadForDirectory(dirId);
    final target = item.name.trim().toLowerCase();
    for (final doc in candidates) {
      if (doc.fileName.trim().toLowerCase() != target) continue;
      if (doc.localPath.isEmpty) continue;
      if (!File(doc.localPath).existsSync()) continue;
      return doc.localPath;
    }
    return null;
  }

  void uploadDocument() {
    Get.toNamed(
      Routes.DOCUMENT_SCANNER,
      arguments: VaultRouteArgs(
        directoryId: directoryId,
        directoryName: directoryName,
      ).toMap(),
    );
  }
}
