import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../documents/vault_route_args.dart';

class AddDocumentController extends BaseController {
  AddDocumentController({
    VaultDirectoriesStore? directoriesStore,
    VaultDocumentsStore? documentsStore,
    ImagePicker? imagePicker,
  })  : _directoriesStore = directoriesStore ?? Get.find<VaultDirectoriesStore>(),
        _documentsStore = documentsStore ?? Get.find<VaultDocumentsStore>(),
        _picker = imagePicker ?? ImagePicker(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final VaultDirectoriesStore _directoriesStore;
  final VaultDocumentsStore _documentsStore;
  final ImagePicker _picker;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final titleController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final directories = <VaultDirectoryDef>[].obs;
  final selectedDirectory = Rxn<VaultDirectoryDef>();
  final saving = false.obs;

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
  /// [Routes.REFINE_SCAN] and ultimately save to the vault.
  void goToScanner() {
    final dir = selectedDirectory.value;
    Get.toNamed(
      Routes.DOCUMENT_SCANNER,
      arguments: VaultRouteArgs(
        directoryId: dir?.id,
        directoryName: dir != null ? directoryDisplayName(dir) : null,
      ).toMap(),
    )?.then((_) => Get.back(result: true));
  }

  /// Picks an image from the gallery and saves it as a local vault document.
  Future<void> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;
      await _saveDocument(picked.path);
    } catch (_) {
      showErrorMessage(_isSw ? 'Haikuweza kupata picha' : 'Could not pick image');
    }
  }

  /// Picks any file (falls back to gallery for simplicity; extend
  /// with file_picker package for PDFs etc. when needed).
  Future<void> pickFile() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;
      await _saveDocument(picked.path);
    } catch (_) {
      showErrorMessage(_isSw ? 'Haikuweza kuchagua faili' : 'Could not pick file');
    }
  }

  Future<void> _saveDocument(String localPath) async {
    saving.value = true;
    try {
      final dir = selectedDirectory.value;
      final name = titleController.text.trim();
      final fileName = name.isNotEmpty ? name : localPath.split('/').last;
      final id = '${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode.abs()}';
      await _documentsStore.add(
        StoredVaultDocument(
          id: id,
          directoryId: dir?.id ?? 'general',
          fileName: fileName,
          localPath: localPath,
          createdAt: DateTime.now(),
        ),
      );

      final payload = <String, dynamic>{
        'directoryId': dir?.id ?? 'general',
        'fileName': fileName,
        'localPath': localPath,
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
      Get.back(result: true);
    } catch (e) {
      showErrorMessage(_isSw ? 'Haikuweza kuhifadhi' : 'Could not save document');
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}
