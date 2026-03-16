import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class RefineScanController extends BaseController {
  final blackAndWhiteOn = true.obs;
  final destinationFolder = 'Select folder'.obs;

  /// True while applying rotate/enhance/B&W/crop so UI can show loading.
  final isProcessing = false.obs;

  /// Path of the image currently shown (reactive). Updated after rotate/enhance/B&W/crop.
  final displayPath = Rxn<String>();

  /// Color version of the image (after rotate/enhance/crop, no B&W). Used when toggling B&W off.
  String? _colorPath;

  /// Normalized crop rect (0-1) relative to image. Full image = Rect.fromLTWH(0, 0, 1, 1).
  final cropRect = Rx<Rect>(Rect.fromLTWH(0, 0, 1, 1));

  /// Current display image dimensions (for overlay layout). Updated when image changes.
  final imageWidth = 0.obs;
  final imageHeight = 0.obs;

  /// Optional image path passed from document scanner (arguments may be Map or String).
  String? get scannedImagePath {
    final args = Get.arguments;
    if (args == null) return null;
    if (args is Map && args.containsKey('imagePath')) return args['imagePath'] as String?;
    if (args is String) return args;
    return null;
  }

  @override
  void onReady() {
    super.onReady();
    _initWorkingImage();
  }

  /// Copy scanned image to temp and set initial display path (with optional B&W).
  Future<void> _initWorkingImage() async {
    final source = scannedImagePath;
    if (source == null || source.isEmpty) return;
    final file = File(source);
    if (!file.existsSync()) return;
    try {
      final dir = await getTemporaryDirectory();
      final ext = source.split('.').last.toLowerCase();
      final isJpeg = ext == 'jpg' || ext == 'jpeg';
      final working = '${dir.path}/refine_scan_${DateTime.now().millisecondsSinceEpoch}.${isJpeg ? "jpg" : "png"}';
      await file.copy(working);
      _colorPath = working;
      await _updateDisplayFromColor();
    } catch (e) {
      showErrorMessage('Failed to load image');
    }
  }

  /// Set displayPath from _colorPath, applying B&W if enabled. Updates image dimensions.
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

  /// Apply current crop to the color image and update display. Resets crop to full after.
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
      final outPath = '${dir.path}/refine_scan_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      final outPath = '${dir.path}/refine_scan_rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      image = img.adjustColor(image, contrast: 1.2, saturation: 0.9, brightness: 1.05);
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/refine_scan_enh_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    final outPath = '${dir.path}/refine_scan_bw_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(image));
    return outPath;
  }

  void selectDestinationFolder() {
    destinationFolder.value = 'Legal Documents';
  }

  void retake() {
    Get.offNamed(Routes.DOCUMENT_SCANNER);
  }

  Future<void> saveToVault() async {
    await applyCrop();
    Get.offAllNamed(Routes.DOCUMENTS);
  }

  /// Path to show in preview: displayPath if set, else scannedImagePath.
  String? get pathToDisplay => displayPath.value ?? scannedImagePath;
}
