import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/model/page_state.dart';
import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../documents/vault_route_args.dart';

class RecentDocumentItem {
  final VaultRecentAccessEntry entry;
  final String timeAgo;

  const RecentDocumentItem({required this.entry, required this.timeAgo});
}

class VaultDirectoryItem {
  final String directoryId;
  final String name;
  final int itemCount;
  final DateTime? lastModified;
  final bool isLocked;

  const VaultDirectoryItem({
    required this.directoryId,
    required this.name,
    required this.itemCount,
    this.lastModified,
    this.isLocked = false,
  });

}

class PropertyVaultController extends BaseController {
  PropertyVaultController({
    AppRepository? repository,
    VaultDirectoriesStore? directoriesStore,
    VaultDocumentsStore? documentsStore,
    VaultRecentAccessStore? recentStore,
  })  : _repository = repository ??
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _directoriesStore = directoriesStore ?? VaultDirectoriesStore(),
        _documentsStore = documentsStore ?? VaultDocumentsStore(),
        _recentStore = recentStore ?? VaultRecentAccessStore();

  final AppRepository _repository;
  final VaultDirectoriesStore _directoriesStore;
  final VaultDocumentsStore _documentsStore;
  final VaultRecentAccessStore _recentStore;

  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final recentlyAccessed = <RecentDocumentItem>[].obs;
  final directories = <VaultDirectoryItem>[].obs;
  final loadError = RxnString();

  List<VaultDirectoryItem> _allDirectories = [];

  @override
  void onInit() {
    super.onInit();
    loadVault();
  }

  Future<void> loadVault() async {
    loadError.value = null;
    await runBusy(() async {
      try {
        await _directoriesStore.ensureDefaults();
        await _tryMergeDirectoriesFromApi();
        _allDirectories = _buildDirectoryItems();
        _applySearchFilter();
        _refreshRecent();
      } catch (e) {
        loadError.value = e.toString();
        updatePageState(PageState.FAILED);
      }
    });
  }

  Future<void> _tryMergeDirectoriesFromApi() async {
    try {
      final res = await _repository.getVaultDocuments('all');
      final parsed = _parseDirectoriesFromResponse(res.data);
      if (parsed.isNotEmpty) {
        await _directoriesStore.mergeFromApi(parsed);
      }
    } catch (_) {
      // GET-only API; local directories remain primary.
    }
  }

  static List<VaultDirectoryDef> _parseDirectoriesFromResponse(dynamic data) {
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      if (data['directories'] is List) {
        raw = data['directories'] as List;
      } else if (data['folders'] is List) {
        raw = data['folders'] as List;
      }
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final id = m['id']?.toString() ?? m['directoryId']?.toString() ?? '';
          final name = m['name']?.toString() ?? m['directoryName']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) return null;
          return VaultDirectoryDef(
            id: id,
            nameEn: name,
            nameSw: name,
            isLocked: m['isLocked'] == true || m['locked'] == true,
          );
        })
        .whereType<VaultDirectoryDef>()
        .toList();
  }

  List<VaultDirectoryItem> _buildDirectoryItems() {
    final defs = _directoriesStore.loadDirectories();
    final isSw = Get.locale?.languageCode == 'sw';
    return defs.map((def) {
      final localDocs = _documentsStore
          .loadForDirectory(def.id)
          .where((d) => d.localPath.isNotEmpty && File(d.localPath).existsSync())
          .toList();
      DateTime? latest;
      for (final doc in localDocs) {
        if (latest == null || doc.createdAt.isAfter(latest)) {
          latest = doc.createdAt;
        }
      }
      return VaultDirectoryItem(
        directoryId: def.id,
        name: isSw ? def.nameSw : def.nameEn,
        itemCount: localDocs.length,
        lastModified: latest,
        isLocked: def.isLocked,
      );
    }).toList();
  }

  void _refreshRecent() {
    final top = _recentStore.loadTop(limit: VaultRecentAccessStore.homeLimit);
    recentlyAccessed.assignAll(
      top.map(
        (e) => RecentDocumentItem(
          entry: e,
          timeAgo: _formatTimeAgo(e.lastAccessedAtMs),
        ),
      ),
    );
  }

  static String _formatTimeAgo(int timestampMs) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd/MM').format(
      DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  String formatModified(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    _applySearchFilter();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) {
      directories.assignAll(_allDirectories);
      return;
    }
    directories.assignAll(
      _allDirectories.where((d) => d.name.toLowerCase().contains(q)),
    );
  }

  void viewAllRecent() {
    // Ensure a fresh controller picks up recent-only args (not a prior folder).
    if (Get.isRegistered<DocumentsController>()) {
      Get.delete<DocumentsController>(force: true);
    }
    Get.toNamed(
      Routes.DOCUMENTS,
      arguments: VaultRouteArgs(
        recentOnly: true,
        directoryName: Get.locale?.languageCode == 'sw'
            ? 'Zilizofikiwa hivi karibuni'
            : 'Recently accessed',
      ).toMap(),
    );
  }

  Future<void> openDirectory(VaultDirectoryItem dir) async {
    await _recentStore.recordDirectory(
      directoryId: dir.directoryId,
      displayName: dir.name,
    );
    _refreshRecent();
    Get.toNamed(
      Routes.DOCUMENTS,
      arguments: VaultRouteArgs(
        directoryId: dir.directoryId,
        directoryName: dir.name,
      ).toMap(),
    )?.then((_) => loadVault());
  }

  void openRecent(RecentDocumentItem item) {
    final entry = item.entry;
    if (entry.targetType == VaultRecentTargetType.directory) {
      final dir = _allDirectories.firstWhereOrNull(
        (d) => d.directoryId == entry.targetId,
      );
      if (dir != null) {
        openDirectory(dir);
        return;
      }
      Get.toNamed(
        Routes.DOCUMENTS,
        arguments: VaultRouteArgs(
          directoryId: entry.targetId,
          directoryName: entry.displayName,
        ).toMap(),
      );
      return;
    }
    final dirId = entry.directoryId ?? 'general';
    final dirName = _allDirectories
            .firstWhereOrNull((d) => d.directoryId == dirId)
            ?.name ??
        entry.displayName;
    Get.toNamed(
      Routes.DOCUMENTS,
      arguments: VaultRouteArgs(
        directoryId: dirId,
        directoryName: dirName,
      ).toMap(),
    );
  }

  void onFabTap() {
    Get.toNamed(Routes.ADD_DOCUMENT)?.then((_) => loadVault());
  }

  Future<void> retry() => loadVault();

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
