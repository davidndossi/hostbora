import 'dart:io';

import 'package:get/get.dart';

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
    // TODO: open search
  }

  void selectFilter(DocumentFilter filter) {
    selectedFilter.value = filter;
  }

  void openDocumentOptions(DocumentItem item) {
    // TODO: show bottom sheet or menu (view, download, delete, etc.)
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
