import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widget/undo_snackbar.dart';
import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../vault_route_args.dart';
import '../widgets/vault_documents_search_sheet.dart';

enum DocumentFilter { all, urgent, verified, more }

enum DocumentFileType { pdf, xlsx, image }

class DocumentItem {
  final String name;
  final String size;
  final bool synced;
  final DocumentFileType fileType;
  final String? localPath;
  final String? directoryId;

  /// Recent-folder rows on the recently-accessed View All list.
  final bool isDirectory;

  const DocumentItem({
    required this.name,
    required this.size,
    this.synced = true,
    required this.fileType,
    this.localPath,
    this.directoryId,
    this.isDirectory = false,
  });
}

class DocumentsController extends BaseController {
  DocumentsController({
    AppRepository? repository,
    VaultDocumentsStore? vaultStore,
    VaultRecentAccessStore? recentStore,
    VaultDirectoriesStore? directoriesStore,
  })  : _repository = repository ??
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _vaultStore = vaultStore ?? VaultDocumentsStore(),
        _recentStore = recentStore ?? VaultRecentAccessStore(),
        _directoriesStore = directoriesStore ?? VaultDirectoriesStore();

  final AppRepository _repository;
  final VaultDocumentsStore _vaultStore;
  final VaultRecentAccessStore _recentStore;
  final VaultDirectoriesStore _directoriesStore;

  String? directoryId;
  String? directoryName;
  bool viewAll = false;
  bool recentOnly = false;

  final selectedFilter = DocumentFilter.all.obs;
  final documents = <DocumentItem>[].obs;
  final loading = false.obs;

  bool get isListingAll =>
      !recentOnly &&
      (viewAll ||
          directoryId == null ||
          directoryId!.isEmpty ||
          directoryId == VaultRouteArgs.allDirectoriesId);

  @override
  void onInit() {
    super.onInit();
    _applyRouteArgs();
    _recordDirectoryAccess();
    loadDocuments();
  }

  void _applyRouteArgs() {
    final args = VaultRouteArgs.fromGetArguments();
    recentOnly = args.recentOnly;
    viewAll = !recentOnly && (args.viewAll || args.listsAllDirectories);
    directoryId = recentOnly
        ? VaultRouteArgs.allDirectoriesId
        : (viewAll ? VaultRouteArgs.allDirectoriesId : args.directoryId);
    directoryName = args.directoryName;
  }

  Future<void> _recordDirectoryAccess() async {
    if (recentOnly || isListingAll) return;
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
    loading.value = true;
    try {
      if (recentOnly) {
        documents.assignAll(_itemsFromRecentAccess(includeDirectories: true));
        return;
      }
      final local = _localDocumentsFor(
        isListingAll ? VaultRouteArgs.allDirectoriesId : directoryId!,
      );
      final remote = isListingAll
          ? await _fetchAllRemoteDocuments()
          : await _fetchRemoteDocuments(directoryId!);
      final recent = isListingAll
          ? _itemsFromRecentAccess(includeDirectories: false)
          : const <DocumentItem>[];
      documents.assignAll(_mergeDocuments([local, remote, recent]));
    } catch (_) {
      if (recentOnly) {
        documents.assignAll(_itemsFromRecentAccess(includeDirectories: true));
        return;
      }
      final fallback = <DocumentItem>[
        ..._localDocumentsFor(
          isListingAll
              ? VaultRouteArgs.allDirectoriesId
              : (directoryId ?? 'general'),
        ),
        if (isListingAll) ..._itemsFromRecentAccess(includeDirectories: false),
      ];
      documents.assignAll(_mergeDocuments([fallback]));
    } finally {
      loading.value = false;
    }
  }

  Future<List<DocumentItem>> _fetchAllRemoteDocuments() async {
    await _directoriesStore.ensureDefaults();
    final dirIds = <String>{
      VaultRouteArgs.allDirectoriesId,
      ..._directoriesStore.loadDirectories().map((d) => d.id),
      ..._recentStore
          .loadAll()
          .map((e) => e.directoryId)
          .whereType<String>()
          .where((id) => id.isNotEmpty),
    };
    final batches = await Future.wait(dirIds.map(_fetchRemoteDocuments));
    return batches.expand((e) => e).toList();
  }

  Future<List<DocumentItem>> _fetchRemoteDocuments(String dirId) async {
    try {
      final res = await _repository.getVaultDocuments(dirId);
      final data = res.data;
      List<dynamic> rawList = [];
      if (data is List) {
        // `/all` may return directories — only keep entries that look like files.
        rawList = data.where((e) {
          if (e is! Map) return false;
          final m = Map<String, dynamic>.from(e);
          final name =
              m['name']?.toString() ?? m['fileName']?.toString() ?? '';
          if (name.isEmpty) return false;
          if (m.containsKey('directories') || m.containsKey('folders')) {
            return false;
          }
          final hasFileHint = m.containsKey('fileName') ||
              m.containsKey('size') ||
              m.containsKey('extension') ||
              m.containsKey('fileType') ||
              m.containsKey('url') ||
              m.containsKey('localPath') ||
              name.contains('.');
          // When fetching a specific folder, accept name-only rows.
          if (dirId != VaultRouteArgs.allDirectoriesId) return true;
          return hasFileHint;
        }).toList();
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
          .whereType<Map>()
          .map((e) => _itemFromMap(Map<String, dynamic>.from(e), dirId))
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

  List<DocumentItem> _itemsFromRecentAccess({
    required bool includeDirectories,
  }) {
    final items = <DocumentItem>[];
    final isSw = Get.locale?.languageCode == 'sw';
    for (final entry in _recentStore.loadAll()) {
      if (entry.targetType == VaultRecentTargetType.directory) {
        if (!includeDirectories) continue;
        if (entry.displayName.trim().isEmpty) continue;
        items.add(
          DocumentItem(
            name: entry.displayName,
            size: isSw ? 'Folda' : 'Folder',
            synced: true,
            fileType: DocumentFileType.pdf,
            directoryId: entry.targetId,
            isDirectory: true,
          ),
        );
        continue;
      }
      final path = entry.localPath?.trim();
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        items.add(
          DocumentItem(
            name: entry.displayName,
            size: _formatBytes(File(path).lengthSync()),
            synced: false,
            fileType: _fileTypeFromName(entry.displayName),
            localPath: path,
            directoryId: entry.directoryId,
          ),
        );
        continue;
      }
      // Still surface recently opened docs that are only known by name so
      // View All never looks emptier than the Recently Accessed strip.
      if (entry.displayName.trim().isEmpty) continue;
      items.add(
        DocumentItem(
          name: entry.displayName,
          size: '',
          synced: true,
          fileType: _fileTypeFromName(entry.displayName),
          directoryId: entry.directoryId,
        ),
      );
    }
    return items;
  }

  static List<DocumentItem> _mergeDocuments(List<List<DocumentItem>> batches) {
    final seen = <String>{};
    final merged = <DocumentItem>[];
    for (final batch in batches) {
      for (final item in batch) {
        final key = item.isDirectory
            ? 'dir:${(item.directoryId ?? item.name).trim().toLowerCase()}'
            : item.name.trim().toLowerCase();
        if (key.isEmpty || key == 'dir:' || !seen.add(key)) continue;
        merged.add(item);
      }
    }
    return merged;
  }

  static DocumentItem _itemFromStored(StoredVaultDocument d) {
    final file = File(d.localPath);
    final bytes = file.existsSync() ? file.lengthSync() : 0;
    return DocumentItem(
      name: d.fileName,
      size: _formatBytes(bytes),
      synced: d.synced,
      fileType: DocumentFileType.image,
      localPath: d.localPath,
      directoryId: d.directoryId,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static DocumentFileType _fileTypeFromName(String name) {
    final i = name.lastIndexOf('.');
    final ext = i >= 0 && i < name.length - 1
        ? name.substring(i + 1).toLowerCase()
        : '';
    if (ext.contains('xls') || ext == 'xlsx') return DocumentFileType.xlsx;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return DocumentFileType.image;
    }
    return DocumentFileType.pdf;
  }

  static DocumentItem _itemFromMap(Map<String, dynamic> m, String dirId) {
    final name = m['name']?.toString() ?? m['fileName']?.toString() ?? '';
    final size = m['size']?.toString() ?? m['sizeFormatted']?.toString() ?? '';
    final synced = m['synced'] as bool? ?? true;
    var ext =
        (m['extension']?.toString() ?? m['fileType']?.toString() ?? '')
            .toLowerCase();
    if (ext.isEmpty && name.isNotEmpty) {
      final i = name.lastIndexOf('.');
      if (i >= 0 && i < name.length - 1) {
        ext = name.substring(i + 1).toLowerCase();
      }
    }
    DocumentFileType fileType = DocumentFileType.pdf;
    if (ext.contains('xls') || ext == 'xlsx') {
      fileType = DocumentFileType.xlsx;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      fileType = DocumentFileType.image;
    }
    return DocumentItem(
      name: name,
      size: size,
      synced: synced,
      fileType: fileType,
      localPath: m['localPath']?.toString(),
      directoryId: m['directoryId']?.toString() ?? dirId,
    );
  }

  void goBack() => Get.back();

  void openSearch() {
    final source = List<DocumentItem>.from(documents);
    Get.bottomSheet(
      VaultDocumentsSearchSheet(
        source: source,
        hintText: appLocalization.searchVaultDocuments,
        emptyLabel: appLocalization.noDocuments,
        onOpenItem: (item) {
          Get.back();
          openDocumentOptions(item);
        },
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
    if (item.isDirectory) {
      _openRecentDirectory(item);
      return;
    }
    Get.bottomSheet(
      SafeArea(
        child: Builder(
          builder: (sheetContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open'),
                  onTap: () async {
                    Get.back();
                    await Future<void>.delayed(const Duration(milliseconds: 120));
                    await _openDocument(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(appLocalization.share),
                  onTap: () async {
                    final origin = _shareOrigin(sheetContext);
                    Get.back();
                    // Wait for the sheet to finish dismissing — sharing
                    // immediately often fails silently on iOS/iPad.
                    await Future<void>.delayed(const Duration(milliseconds: 200));
                    await _shareDocument(item, shareOrigin: origin);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove from list'),
                  onTap: () {
                    final index = documents.indexOf(item);
                    Get.back();
                    if (index < 0) return;
                    documents.removeAt(index);
                    hapticPrimaryConfirm();
                    final ctx = Get.context;
                    if (ctx != null && ctx.mounted) {
                      UndoSnackBar.show(
                        ctx,
                        message: 'Document removed from list',
                        onUndo: () {
                          if (index <= documents.length) {
                            documents.insert(index, item);
                          } else {
                            documents.add(item);
                          }
                        },
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(appLocalization.cancel),
                  onTap: Get.back,
                ),
              ],
            );
          },
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _openRecentDirectory(DocumentItem item) {
    final dirId = item.directoryId?.trim() ?? '';
    if (dirId.isEmpty) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Folda haipatikani.'
            : 'Folder is unavailable.',
      );
      return;
    }
    if (Get.isRegistered<DocumentsController>()) {
      Get.delete<DocumentsController>(force: true);
    }
    Get.offNamed(
      Routes.DOCUMENTS,
      arguments: VaultRouteArgs(
        directoryId: dirId,
        directoryName: item.name,
      ).toMap(),
    );
  }

  Future<void> _openDocument(DocumentItem item) async {
    final path = _resolveLocalPath(item);
    if (path == null) {
      showErrorMessage(_offlineUnavailableMessage());
      return;
    }
    final opened = await OpenFile.open(path);
    if (opened.type == ResultType.noAppToOpen) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Hakuna programu ya kufungua faili hii.'
            : 'No app found to open this file.',
      );
      return;
    }
    if (opened.type == ResultType.error) {
      showErrorMessage(opened.message.isNotEmpty
          ? opened.message
          : (Get.locale?.languageCode == 'sw'
              ? 'Imeshindikana kufungua waraka.'
              : 'Could not open this document.'));
      return;
    }
    await _recentStore.recordDocument(
      documentId:
          '${item.directoryId ?? directoryId ?? 'all'}:${item.name.toLowerCase()}',
      displayName: item.name,
      directoryId: item.directoryId ?? directoryId,
      localPath: path,
    );
  }

  Future<void> _shareDocument(
    DocumentItem item, {
    Rect? shareOrigin,
  }) async {
    final path = _resolveLocalPath(item);
    if (path == null) {
      showErrorMessage(_offlineUnavailableMessage());
      return;
    }
    try {
      await _recentStore.recordDocument(
        documentId:
            '${item.directoryId ?? directoryId ?? 'all'}:${item.name.toLowerCase()}',
        displayName: item.name,
        directoryId: item.directoryId ?? directoryId,
        localPath: path,
      );
      final xFile = XFile(
        path,
        name: item.name,
        mimeType: _mimeTypeFor(item),
      );
      var origin = shareOrigin ?? _shareOrigin(Get.context);
      try {
        await Share.shareXFiles(
          [xFile],
          subject: item.name,
          text: item.name,
          sharePositionOrigin: origin,
        );
      } catch (_) {
        final size = Get.size;
        origin = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 2,
          height: 2,
        );
        await Share.shareXFiles(
          [xFile],
          subject: item.name,
          text: item.name,
          sharePositionOrigin: origin,
        );
      }
    } catch (e, st) {
      logger.e('Document share failed: $e\n$st');
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Imeshindikana kushiriki waraka. Jaribu tena.'
            : 'Could not open sharing options. Please try again.',
      );
    }
  }

  String _offlineUnavailableMessage() {
    return Get.locale?.languageCode == 'sw'
        ? 'Waraka haupatikani nje ya mtandao. Fungua folda uliyohifadhiwa au skani tena.'
        : 'This document is not available offline. Open its folder or scan it again.';
  }

  static String? _mimeTypeFor(DocumentItem item) {
    switch (item.fileType) {
      case DocumentFileType.pdf:
        return 'application/pdf';
      case DocumentFileType.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case DocumentFileType.image:
        final lower = item.name.toLowerCase();
        if (lower.endsWith('.png')) return 'image/png';
        if (lower.endsWith('.webp')) return 'image/webp';
        if (lower.endsWith('.gif')) return 'image/gif';
        return 'image/jpeg';
    }
  }

  Rect? _shareOrigin(BuildContext? context) {
    final ctx = context;
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width <= 0 || origin.height <= 0) return null;
    return origin;
  }

  String? _resolveLocalPath(DocumentItem item) {
    final direct = item.localPath?.trim();
    if (direct != null &&
        direct.isNotEmpty &&
        File(direct).existsSync()) {
      return direct;
    }
    final dirId = isListingAll
        ? VaultRouteArgs.allDirectoriesId
        : (directoryId ?? 'all');
    final candidates = _vaultStore.loadForDirectory(dirId);
    final target = item.name.trim().toLowerCase();
    for (final doc in candidates) {
      if (doc.fileName.trim().toLowerCase() != target) continue;
      if (doc.localPath.isEmpty) continue;
      if (!File(doc.localPath).existsSync()) continue;
      return doc.localPath;
    }
    // Fall back to recently accessed entries for the same display name.
    for (final entry in _recentStore.loadAll()) {
      if (entry.targetType != VaultRecentTargetType.document) continue;
      if (entry.displayName.trim().toLowerCase() != target) continue;
      final path = entry.localPath?.trim();
      if (path == null || path.isEmpty) continue;
      if (!File(path).existsSync()) continue;
      return path;
    }
    return null;
  }

  void uploadDocument() {
    Get.toNamed(
      Routes.DOCUMENT_SCANNER,
      arguments: VaultRouteArgs(
        directoryId: isListingAll ? 'general' : directoryId,
        directoryName: isListingAll ? null : directoryName,
      ).toMap(),
    );
  }
}
