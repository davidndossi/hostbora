import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widget/undo_snackbar.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/not_found_exception.dart';
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
    OfflineSyncQueueLocalDataSource? syncQueue,
    OfflineSyncWorkerService? syncWorker,
  })  : _repository = repository ??
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _vaultStore = vaultStore ?? VaultDocumentsStore(),
        _recentStore = recentStore ?? VaultRecentAccessStore(),
        _directoriesStore = directoriesStore ?? VaultDirectoriesStore(),
        _syncQueue = syncQueue ?? Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = syncWorker ?? Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final VaultDocumentsStore _vaultStore;
  final VaultRecentAccessStore _recentStore;
  final VaultDirectoriesStore _directoriesStore;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

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
        documents.assignAll(
          _present(_itemsFromRecentAccess(includeDirectories: true)),
        );
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
      documents.assignAll(
        _present(_mergeDocuments([local, remote, recent])),
      );
    } catch (_) {
      if (recentOnly) {
        documents.assignAll(
          _present(_itemsFromRecentAccess(includeDirectories: true)),
        );
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
      documents.assignAll(_present(_mergeDocuments([fallback])));
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
      if (path != null && path.isNotEmpty) {
        if (!File(path).existsSync()) continue;
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

  List<DocumentItem> _present(List<DocumentItem> items) {
    return _withoutRemoved(_withDisplayNames(items));
  }

  List<DocumentItem> _withDisplayNames(List<DocumentItem> items) {
    return items.map((item) {
      if (item.isDirectory) return item;
      final resolved = _vaultStore.resolveDisplayName(item.name);
      if (resolved == item.name) return item;
      return DocumentItem(
        name: resolved,
        size: item.size,
        synced: item.synced,
        fileType: item.fileType,
        localPath: item.localPath,
        directoryId: item.directoryId,
      );
    }).toList();
  }

  List<DocumentItem> _withoutRemoved(List<DocumentItem> items) {
    final hidden = _vaultStore.removedNames();
    if (hidden.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.isDirectory ||
              !hidden.contains(item.name.trim().toLowerCase()),
        )
        .toList();
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

  Future<void> editDocumentName(DocumentItem item) async {
    if (item.isDirectory) return;
    final isSw = Get.locale?.languageCode == 'sw';
    final field = TextEditingController(text: item.name);
    final saved = await Get.dialog<String>(
      AlertDialog(
        title: Text(isSw ? 'Hariri jina la hati' : 'Edit document name'),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: isSw ? 'Jina la hati' : 'Document name',
          ),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(appLocalization.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: field.text.trim()),
            child: Text(appLocalization.save),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => field.dispose());
    final next = saved?.trim() ?? '';
    if (next.isEmpty || next.toLowerCase() == item.name.trim().toLowerCase()) {
      return;
    }
    await _vaultStore.renameDisplayName(fromName: item.name, toName: next);
    await _recentStore.renameDocumentsNamed(item.name, next);
    final key = item.name.trim().toLowerCase();
    final index = documents.indexWhere(
      (d) => !d.isDirectory && d.name.trim().toLowerCase() == key,
    );
    if (index < 0) return;
    final current = documents[index];
    documents[index] = DocumentItem(
      name: next,
      size: current.size,
      synced: current.synced,
      fileType: current.fileType,
      localPath: current.localPath,
      directoryId: current.directoryId,
    );
    hapticPrimaryConfirm();
    await _syncDocumentRename(
      directoryId: _syncDirectoryId(item),
      fromName: item.name,
      toName: next,
      localPath: item.localPath,
    );
  }

  Future<void> _removeDocumentFromList(DocumentItem item) async {
    final name = item.name.trim();
    if (name.isEmpty || item.isDirectory) return;
    final key = name.toLowerCase();
    final index = documents.indexWhere(
      (d) => !d.isDirectory && d.name.trim().toLowerCase() == key,
    );

    final aliases = _vaultStore.namesResolvingTo(name);
    for (final alias in aliases) {
      await _vaultStore.hideName(alias);
    }
    await _vaultStore.hideName(name);
    final removedStored = <StoredVaultDocument>[];
    for (final alias in {name, ...aliases}) {
      removedStored.addAll(await _vaultStore.removeByFileName(alias));
    }
    final removedRecent = await _recentStore.removeDocumentsNamed(
      name,
      localPath: item.localPath,
      alsoNames: aliases,
    );
    documents.removeWhere(
      (d) => !d.isDirectory && d.name.trim().toLowerCase() == key,
    );
    hapticPrimaryConfirm();
    await _syncDocumentDelete(
      directoryId: _syncDirectoryId(item, stored: removedStored),
      fileNames: {
        name,
        ...removedStored.map((doc) => doc.fileName),
      },
      localPath: item.localPath,
      stored: removedStored,
    );

    final ctx = Get.context;
    if (ctx == null || !ctx.mounted) return;
    UndoSnackBar.show(
      ctx,
      message: 'Document removed from list',
      onUndo: () {
        _restoreRemovedDocument(
          item: item,
          index: index,
          stored: removedStored,
          recent: removedRecent,
        );
      },
    );
  }

  Future<void> _restoreRemovedDocument({
    required DocumentItem item,
    required int index,
    required List<StoredVaultDocument> stored,
    required List<VaultRecentAccessEntry> recent,
  }) async {
    final aliases = _vaultStore.namesResolvingTo(item.name);
    for (final alias in aliases) {
      await _vaultStore.unhideName(alias);
    }
    await _vaultStore.unhideName(item.name);
    for (final doc in stored) {
      await _vaultStore.add(doc);
    }
    for (final entry in recent) {
      await _recentStore.recordDocument(
        documentId: entry.targetId,
        displayName: entry.displayName,
        directoryId: entry.directoryId,
        localPath: entry.localPath,
      );
    }
    final key = item.name.trim().toLowerCase();
    final alreadyShown = documents.any(
      (d) => !d.isDirectory && d.name.trim().toLowerCase() == key,
    );
    if (alreadyShown) return;
    if (index >= 0 && index <= documents.length) {
      documents.insert(index, item);
    } else {
      documents.add(item);
    }
    if (stored.isEmpty) {
      await _syncDocumentCreate(
        directoryId: _syncDirectoryId(item),
        fileName: item.name,
        localPath: item.localPath ?? '',
      );
      return;
    }
    for (final doc in stored) {
      await _syncQueue.deleteByDedupeKey(
        _deleteDedupeKey(doc.directoryId, doc.fileName),
      );
      await _syncDocumentCreate(
        directoryId: doc.directoryId,
        fileName: doc.fileName,
        localPath: doc.localPath,
        localId: doc.id,
      );
    }
  }

  String _syncDirectoryId(
    DocumentItem item, {
    List<StoredVaultDocument> stored = const [],
  }) {
    for (final doc in stored) {
      final id = doc.directoryId.trim();
      if (id.isNotEmpty && id != VaultRouteArgs.allDirectoriesId) return id;
    }
    final id = item.directoryId?.trim() ?? '';
    if (id.isEmpty || id == VaultRouteArgs.allDirectoriesId) return 'general';
    return id;
  }

  bool _syncOk(String? code) {
    return code == '0' ||
        code == '200' ||
        code == '201' ||
        code == '204';
  }

  Future<void> _syncDocumentRename({
    required String directoryId,
    required String fromName,
    required String toName,
    String? localPath,
  }) async {
    final payload = <String, dynamic>{
      'directoryId': directoryId,
      'fileName': fromName,
      'newFileName': toName,
      'localPath': localPath ?? '',
      'notes': '',
    };
    try {
      final res = await _repository.updateVaultDocument(payload);
      if (!_syncOk(res.responseCode)) {
        throw Exception(res.message ?? 'API error');
      }
    } on NotFoundException {
      await _syncDocumentCreate(
        directoryId: directoryId,
        fileName: toName,
        localPath: localPath ?? '',
      );
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'document',
        operation: 'update',
        payloadJson: jsonEncode(payload),
        dedupeKey:
            'document:update:$directoryId:${fromName.toLowerCase()}:${toName.toLowerCase()}',
      );
      _syncWorker.runNow();
    }
  }

  Future<void> _syncDocumentDelete({
    required String directoryId,
    required Set<String> fileNames,
    String? localPath,
    required List<StoredVaultDocument> stored,
  }) async {
    for (final doc in stored) {
      await _syncQueue.deleteByDedupeKey('document:create:${doc.id}');
    }
    final names = fileNames.map((name) => name.trim()).where((name) => name.isNotEmpty);
    for (final fileName in names) {
      final payload = <String, dynamic>{
        'directoryId': directoryId,
        'fileName': fileName,
        'localPath': localPath ?? '',
      };
      try {
        final res = await _repository.deleteVaultDocument(
          directoryId: directoryId,
          fileName: fileName,
        );
        if (!_syncOk(res.responseCode) && res.responseCode != '404') {
          throw Exception(res.message ?? 'API error');
        }
      } on NotFoundException {
        continue;
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'document',
          operation: 'delete',
          payloadJson: jsonEncode(payload),
          dedupeKey: _deleteDedupeKey(directoryId, fileName),
        );
        _syncWorker.runNow();
      }
    }
  }

  Future<void> _syncDocumentCreate({
    required String directoryId,
    required String fileName,
    required String localPath,
    String? localId,
  }) async {
    final payload = <String, dynamic>{
      'directoryId': directoryId,
      'fileName': fileName,
      'localPath': localPath,
      'notes': '',
    };
    try {
      final res = await _repository.uploadVaultDocument(payload);
      if (!_syncOk(res.responseCode)) {
        throw Exception(res.message ?? 'API error');
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'document',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'document:create:${localId ?? fileName.toLowerCase()}',
      );
      _syncWorker.runNow();
    }
  }

  String _deleteDedupeKey(String directoryId, String fileName) {
    return 'document:delete:$directoryId:${fileName.trim().toLowerCase()}';
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
                  leading: const Icon(Icons.open_in_new_outlined),
                  title: const Text('Open'),
                  onTap: () async {
                    Get.back();
                    await Future<void>.delayed(const Duration(milliseconds: 120));
                    await _openDocument(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(
                    Get.locale?.languageCode == 'sw'
                        ? 'Hariri jina'
                        : 'Edit name',
                  ),
                  onTap: () {
                    Get.back();
                    editDocumentName(item);
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
                    Get.back();
                    _removeDocumentFromList(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close_outlined),
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
    var dirId = item.directoryId?.trim() ?? '';
    if (dirId.isEmpty) {
      final match = _directoriesStore.loadDirectories().firstWhereOrNull((d) {
        final en = d.nameEn.trim().toLowerCase();
        final sw = d.nameSw.trim().toLowerCase();
        final name = item.name.trim().toLowerCase();
        return en == name || sw == name;
      });
      dirId = match?.id ?? '';
    }
    if (dirId.isEmpty) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Folda haipatikani.'
            : 'Folder is unavailable.',
      );
      return;
    }
    final args = VaultRouteArgs(
      directoryId: dirId,
      directoryName: item.name,
    ).toMap();
    // Leave the recent list, then open the folder with a fresh controller.
    // Deleting while still on this route can swallow the tap / navigation.
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
    Future.microtask(() {
      if (Get.isRegistered<DocumentsController>()) {
        Get.delete<DocumentsController>(force: true);
      }
      Get.toNamed(Routes.DOCUMENTS, arguments: args);
    });
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
