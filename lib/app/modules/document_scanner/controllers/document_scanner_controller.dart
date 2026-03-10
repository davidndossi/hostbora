import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class DocumentScannerController extends BaseController {
  final flashOn = false.obs;
  final autoCaptureOn = true.obs;

  final isCameraReady = false.obs;
  final cameraError = ''.obs;
  /// True when permission was denied so the UI can show "Open Settings" / retry.
  final showPermissionActions = false.obs;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  CameraController? get cameraController => _cameraController;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  @override
  void onClose() {
    _disposeCamera();
    super.onClose();
  }

  Future<void> _initCamera() async {
    try {
      cameraError.value = '';
      showPermissionActions.value = false;

      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) {
        cameraError.value = status.isPermanentlyDenied
            ? 'Camera access was denied. Please enable it in Settings to scan documents.'
            : 'Camera permission is needed to scan documents.';
        showPermissionActions.value = true;
        _showCameraPermissionDialog();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        cameraError.value = 'No camera found';
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      isCameraReady.value = true;
    } catch (e) {
      cameraError.value = e.toString();
    }
  }

  Future<void> _disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    isCameraReady.value = false;
  }

  void close() => Get.back();

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final next = !flashOn.value;
      await _cameraController!.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      flashOn.value = next;
    } catch (_) {}
  }

  void toggleAutoCapture() {
    autoCaptureOn.value = !autoCaptureOn.value;
  }

  void importFromGallery() async {
    Get.toNamed(Routes.REFINE_SCAN);
  }

  Future<void> capture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) return;
    try {
      final file = await _cameraController!.takePicture();
      final path = file.path;
      if (path.isNotEmpty) {
        Get.toNamed(Routes.REFINE_SCAN, arguments: {'imagePath': path});
      }
    } catch (e) {
      showErrorMessage('Capture failed');
    }
  }

  void batchMode() {
    autoCaptureOn.value = false;
  }

  /// Retry after user may have granted permission in settings.
  Future<void> retryPermission() async {
    _initCamera();
  }

  /// Open app settings so the user can enable camera permission.
  Future<void> openAppSettingsForCamera() async {
    await openAppSettings();
  }

  void _showCameraPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Camera access required'),
        content: const Text(
          'To scan documents we need access to your camera. '
          'Please open Settings and allow camera permission for this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettingsForCamera();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
