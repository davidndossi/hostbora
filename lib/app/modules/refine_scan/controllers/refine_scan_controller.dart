import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../../../routes/app_pages.dart';
import '../../documents/controllers/documents_controller.dart';
import '../../documents/vault_route_args.dart';

class RefineScanController extends BaseController {
  RefineScanController({
    VaultDocumentsStore? vaultStore,
    VaultRecentAccessStore? recentStore,
  })  : _vaultStore = vaultStore ?? VaultDocumentsStore(),
        _recentStore = recentStore ?? VaultRecentAccessStore();

  final VaultDocumentsStore _vaultStore;
  final VaultRecentAccessStore _recentStore;

  final blackAndWhiteOn = true.obs;
  final destinationFolder = ''.obs;
  final isProcessing = false.obs;
  final isSaving = false.obs;
  final displayPath = Rxn<String>();
  final cropRect = Rx<Rect>(Rect.fromLTWH(0, 0, 1, 1));
  final imageWidth = 0.obs;
  final imageHeight = 0.obs;

  String? _colorPath;
  late VaultRouteArgs _vaultArgs;

  String? get scannedImagePath {
    final path = _vaultArgs.imagePath;
    if (path != null && path.isNotEmpty) return path;
    return null;
  }

  bool get hasLoadedImage {
    final path = pathToDisplay;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  bool get canSave => hasLoadedImage && !isProcessing.value && !isSaving.value;

  String? get pathToDisplay => displayPath.value ?? scannedImagePath;

  @override
  void onInit() {
    super.onInit();
    _vaultArgs = VaultRouteArgs.fromGetArguments();
    destinationFolder.value = _vaultArgs.effectiveDirectoryName;
  }

  @override
  void onReady() {
    super.onReady();
    _initWorkingImage();
  }

  Future<void> _initWorkingImage() async {
    final source = scannedImagePath;
    if (source == null || source.isEmpty) return;
    final file = File(source);
    if (!file.existsSync()) return;
    try {
      final dir = await getTemporaryDirectory();
      final ext = source.split('.').last.toLowerCase();
      final isJpeg = ext == 'jpg' || ext == 'jpeg';
      final working =
          '${dir.path}/refine_scan_${DateTime.now().millisecondsSinceEpoch}.${isJpeg ? "jpg" : "png"}';
      await file.copy(working);
      _colorPath = working;
      await _updateDisplayFromColor();
    } catch (e) {
      showErrorMessage('Failed to load image');
    }
  }

  Future<void> _updateDisplayFromColor() async {
    if (_colorPath == null) return;
    try {
      if (blackAndWhiteOn.value) {
        final out = await _applyGrayscale(_colorPath!);
        if (out != null) displayPath.value = out;
      } else {
        displayPath.value = _colorPath;
      }
      _setImageDimensionsFromPath(_colorPath!);
      cropRect.value = Rect.fromLTWH(0, 0, 1, 1);
    } catch (e) {
      displayPath.value = _colorPath;
    }
  }

  void _setImageDimensionsFromPath(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image != null) {
        imageWidth.value = image.width;
        imageHeight.value = image.height;
        return;
      }
    } catch (_) {}
    Future.microtask(() async {
      try {
        final bytes = await File(path).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null && imageWidth.value == 0) {
          imageWidth.value = image.width;
          imageHeight.value = image.height;
        }
      } catch (_) {}
    });
  }

  void setCropRect(Rect normalized) {
    cropRect.value = normalized;
  }

  Future<void> applyCrop() async {
    if (_colorPath == null) return;
    final r = cropRect.value;
    if (r.left <= 0 && r.top <= 0 && r.right >= 1 && r.bottom >= 1) return;
    isProcessing.value = true;
    try {
      final bytes = await File(_colorPath!).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        showErrorMessage('Could not decode image');
        return;
      }
      final w = image.width;
      final h = image.height;
      final x = (r.left * w).round().clamp(0, w);
      final y = (r.top * h).round().clamp(0, h);
      final cw = (r.width * w).round().clamp(1, w - x);
      final ch = (r.height * h).round().clamp(1, h - y);
      image = img.copyCrop(image, x: x, y: y, width: cw, height: ch);
      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/refine_scan_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
      _colorPath = outPath;
      await _updateDisplayFromColor();
    } catch (e) {
      showErrorMessage('Crop failed');
    } finally {
      isProcessing.value = false;
    }
  }

  void goBack() => Get.back();

  Future<void> rotate() async {
    if (_colorPath == null) return;
    isProcessing.value = true;
    try {
      final bytes = await File(_colorPath!).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        showErrorMessage('Could not decode image');
        return;
      }
      image = img.copyRotate(image, angle: 90);
      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/refine_scan_rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
      _colorPath = outPath;
      await _updateDisplayFromColor();
    } catch (e) {
      showErrorMessage('Rotate failed');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> enhance() async {
    if (_colorPath == null) return;
    isProcessing.value = true;
    try {
      final bytes = await File(_colorPath!).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        showErrorMessage('Could not decode image');
        return;
      }
      image = img.adjustColor(
        image,
        contrast: 1.2,
        saturation: 0.9,
        brightness: 1.05,
      );
      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/refine_scan_enh_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
      _colorPath = outPath;
      await _updateDisplayFromColor();
    } catch (e) {
      showErrorMessage('Enhance failed');
    } finally {
      isProcessing.value = false;
    }
  }

  void toggleBlackAndWhite() {
    if (_colorPath == null) return;
    isProcessing.value = true;
    blackAndWhiteOn.value = !blackAndWhiteOn.value;
    _updateDisplayFromColor().whenComplete(() => isProcessing.value = false);
  }

  Future<String?> _applyGrayscale(String inputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;
    image = img.grayscale(image);
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/refine_scan_bw_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(image));
    return outPath;
  }

  void retake() {
    Get.offNamed(
      Routes.DOCUMENT_SCANNER,
      arguments: _vaultArgs.toMap(),
    );
  }

  Future<void> saveToVault() async {
    if (!canSave) return;
    isSaving.value = true;
    try {
      await applyCrop();
      final source = pathToDisplay;
      if (source == null || !File(source).existsSync()) {
        showErrorMessage('No image to save');
        return;
      }

      final dirId = _vaultArgs.effectiveDirectoryId;
      final persistedPath = await _persistToVaultDirectory(source, dirId);
      final stamp = DateTime.now();
      final fileName =
          'Scan_${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_${stamp.hour}${stamp.minute}.jpg';

      final docId = 'local_${stamp.millisecondsSinceEpoch}';
      await _vaultStore.add(
        StoredVaultDocument(
          id: docId,
          directoryId: dirId,
          fileName: fileName,
          localPath: persistedPath,
          createdAt: stamp,
          synced: false,
        ),
      );

      await _recentStore.recordDocument(
        documentId: docId,
        displayName: fileName,
        directoryId: dirId,
        localPath: persistedPath,
      );

      _returnToDocumentsAndReload();
      showSuccessMessage(appLocalization.vaultDocumentSaved);
    } catch (e) {
      showErrorMessage('Could not save document');
    } finally {
      isSaving.value = false;
    }
  }

  Future<String> _persistToVaultDirectory(String sourcePath, String directoryId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vault/$directoryId');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${vaultDir.path}/$fileName');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  void _returnToDocumentsAndReload() {
    final args = _vaultArgs.toMap();
    Get.until((route) => route.settings.name == Routes.DOCUMENTS);
    if (Get.isRegistered<DocumentsController>()) {
      final docs = Get.find<DocumentsController>();
      docs.directoryId = _vaultArgs.directoryId;
      docs.directoryName = _vaultArgs.directoryName;
      docs.loadDocuments();
    } else {
      Get.offNamed(Routes.DOCUMENTS, arguments: args);
    }
  }
}
