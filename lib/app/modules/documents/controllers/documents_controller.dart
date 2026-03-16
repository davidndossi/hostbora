import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

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
  DocumentsController() : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  /// Directory when opened from property vault; null when opened from settings (show all or default).
  String? directoryId;
  String? directoryName;

  final selectedFilter = DocumentFilter.all.obs;
  final documents = <DocumentItem>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      directoryId = args['directoryId']?.toString();
      directoryName = args['directoryName']?.toString();
    }
    loadDocuments();
  }

  /// Fetches documents from service for the current directory (no static list).
  Future<void> loadDocuments() async {
    final dirId = directoryId ?? 'all';
    loading.value = true;
    try {
      final res = await _repository.getVaultDocuments(dirId);
      final data = res.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['documents'] is List) rawList = data['documents'] as List;
        else if (data['files'] is List) rawList = data['files'] as List;
        else if (data['content'] is List) rawList = data['content'] as List;
      }
      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map(_itemFromMap)
          .where((e) => e.name.isNotEmpty)
          .toList();
      documents.assignAll(list);
    } catch (_) {
      documents.clear();
    } finally {
      loading.value = false;
    }
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
    if (ext.contains('xls') || ext == 'xlsx') fileType = DocumentFileType.xlsx;
    else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) fileType = DocumentFileType.image;
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
    Get.toNamed(Routes.DOCUMENT_SCANNER);
  }
}
