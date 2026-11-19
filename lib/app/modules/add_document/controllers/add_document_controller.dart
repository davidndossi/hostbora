import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../documents/vault_route_args.dart';

class AddDocumentController extends BaseController {
  AddDocumentController({
    VaultDirectoriesStore? directoriesStore,
    VaultDocumentsStore? documentsStore,
    VaultRecentAccessStore? recentStore,
    ImagePicker? imagePicker,
  })  : _directoriesStore = directoriesStore ?? Get.find<VaultDirectoriesStore>(),
        _documentsStore = documentsStore ?? Get.find<VaultDocumentsStore>(),
        _recentStore = recentStore ?? VaultRecentAccessStore(),
        _picker = imagePicker ?? ImagePicker(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final VaultDirectoriesStore _directoriesStore;
  final VaultDocumentsStore _documentsStore;
  final VaultRecentAccessStore _recentStore;
  final ImagePicker _picker;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final titleController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final directories = <VaultDirectoryDef>[].obs;
  final selectedDirectory = Rxn<VaultDirectoryDef>();
  final saving = false.obs;
  final pendingPath = RxnString();
  final pendingFileName = ''.obs;
  final pendingIsImage = false.obs;

  bool get hasPendingFile {
    final path = pendingPath.value?.trim() ?? '';
    return path.isNotEmpty;
  }

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    _loadDirectories();

    // Pre-select a directory if the caller passed one via route args.
    final args = VaultRouteArgs.fromGetArguments();
    if (args.directoryId != null && args.directoryId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preselectDirectory(args.directoryId!);
      });
    }
  }

  void _loadDirectories() {
    try {
      final defs = _directoriesStore.loadDirectories();
      directories.assignAll(defs);
      if (selectedDirectory.value == null && defs.isNotEmpty) {
        selectedDirectory.value = defs.first;
      }
    } catch (_) {
      directories.clear();
    }
  }

  void _preselectDirectory(String id) {
    final match = directories.firstWhereOrNull((d) => d.id == id);
    if (match != null) selectedDirectory.value = match;
  }

  void selectDirectory(VaultDirectoryDef? def) {
    selectedDirectory.value = def;
  }

  String directoryDisplayName(VaultDirectoryDef def) =>
      _isSw ? def.nameSw : def.nameEn;

  /// Opens the document scanner. The scanner will pass back through
  /// [Routes.REFINE_SCAN] and ultimately navigate to the vault on save.
  /// Do not auto-[Get.back] when the scanner closes — save already pops
  /// past this screen, and an extra back left a blank page.
  void goToScanner() {
    final dir = selectedDirectory.value;
    Get.toNamed(
      Routes.DOCUMENT_SCANNER,
      arguments: VaultRouteArgs(
        directoryId: dir?.id,
        directoryName: dir != null ? directoryDisplayName(dir) : null,
      ).toMap(),
    );
  }

  /// Picks an image from the gallery and shows a preview. Saving is explicit.
  Future<void> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;
      _stageFile(picked.path, picked.name);
    } catch (_) {
      showErrorMessage(_isSw ? 'Haikuweza kupata picha' : 'Could not pick image');
    }
  }

  /// Picks a file from device storage and shows a preview. Saving is explicit.
  Future<void> pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.any);
      final file = picked?.files.single;
      final path = file?.path?.trim() ?? '';
      if (file == null || path.isEmpty) return;
      _stageFile(path, file.name);
    } catch (_) {
      showErrorMessage(_isSw ? 'Haikuweza kuchagua faili' : 'Could not pick file');
    }
  }

  void clearPendingFile() {
    pendingPath.value = null;
    pendingFileName.value = '';
    pendingIsImage.value = false;
  }

  void _stageFile(String path, String name) {
    final fileName = name.trim().isNotEmpty ? name.trim() : path.split('/').last;
    pendingPath.value = path;
    pendingFileName.value = fileName;
    pendingIsImage.value = _isImageName(fileName);
    if (titleController.text.trim().isEmpty) {
      titleController.text = _nameWithoutExtension(fileName);
    }
  }

  /// Saves the staged gallery image or file.
  Future<void> savePendingDocument() async {
    final path = pendingPath.value?.trim() ?? '';
    if (path.isEmpty) {
      showErrorMessage(
        _isSw ? 'Chagua hati kwanza' : 'Choose a document first',
      );
      return;
    }
    await _saveDocument(path);
  }

  Future<void> _saveDocument(String localPath) async {
    saving.value = true;
    try {
      final source = File(localPath);
      if (!source.existsSync()) {
        showErrorMessage(
          _isSw ? 'Faili haipatikani tena' : 'That file is no longer available',
        );
        return;
      }
      final dir = selectedDirectory.value;
      final directoryId = dir?.id ?? 'general';
      final fileName = _fileNameForSave(localPath);
      final persistedPath = await _persistCopy(
        sourcePath: localPath,
        directoryId: directoryId,
        fileName: fileName,
      );
      final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await _documentsStore.add(
        StoredVaultDocument(
          id: id,
          directoryId: directoryId,
          fileName: fileName,
          localPath: persistedPath,
          createdAt: DateTime.now(),
        ),
      );
      await _recentStore.recordDocument(
        documentId: id,
        displayName: fileName,
        directoryId: directoryId,
        localPath: persistedPath,
      );

      final payload = <String, dynamic>{
        'directoryId': directoryId,
        'fileName': fileName,
        'localPath': persistedPath,
        'notes': '',
      };
      try {
        final res = await _repository.uploadVaultDocument(payload);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'API error');
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'document',
          operation: 'create',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'document:create:$id',
        );
        _syncWorker.runNow();
      }

      showSuccessMessage(_isSw ? 'Hati imehifadhiwa' : 'Document saved');
      if (Get.isRegistered<DocumentsController>()) {
        await Get.find<DocumentsController>().loadDocuments();
      }
      Get.back(result: true);
    } catch (e) {
      showErrorMessage(_isSw ? 'Haikuweza kuhifadhi' : 'Could not save document');
    } finally {
      saving.value = false;
    }
  }

  Future<String> _persistCopy({
    required String sourcePath,
    required String directoryId,
    required String fileName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final safeDir = directoryId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final vaultDir = Directory('${appDir.path}/vault/$safeDir');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    final ext = _extensionOf(fileName);
    final dest = File(
      '${vaultDir.path}/doc_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot >= name.length - 1) return '';
    final ext = name.substring(dot).toLowerCase();
    if (ext.length > 8) return '';
    return ext;
  }

  String _fileNameForSave(String localPath) {
    final typed = titleController.text.trim();
    final original = pendingFileName.value.trim().isNotEmpty
        ? pendingFileName.value.trim()
        : localPath.split('/').last;
    if (typed.isEmpty) return original;
    if (typed.contains('.')) return typed;
    final dot = original.lastIndexOf('.');
    if (dot <= 0 || dot >= original.length - 1) return typed;
    return '$typed${original.substring(dot)}';
  }

  static bool _isImageName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return false;
    const images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
    return images.contains(name.substring(dot + 1).toLowerCase());
  }

  static String _nameWithoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return name;
    return name.substring(0, dot);
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}
