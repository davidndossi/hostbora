import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';
import '../../documents/vault_route_args.dart';

class DocumentScannerController extends BaseController {
  DocumentScannerController({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  final flashOn = false.obs;

  final isCameraReady = false.obs;
  final cameraError = ''.obs;
  final showPermissionActions = false.obs;

  late final VaultRouteArgs _vaultArgs;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  CameraController? get cameraController => _cameraController;

  @override
  void onInit() {
    super.onInit();
    _vaultArgs = VaultRouteArgs.fromGetArguments();
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final next = !flashOn.value;
      await _cameraController!.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      flashOn.value = next;
    } catch (_) {}
  }

  Future<void> importFromGallery() async {
    try {
      var status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      if (!status.isGranted && !status.isLimited) {
        showErrorMessage('Photo library access is needed to import images.');
        return;
      }

      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      final path = picked?.path;
      if (path == null || path.isEmpty) return;

      await _disposeCamera();
      Get.toNamed(
        Routes.REFINE_SCAN,
        arguments: _vaultArgs.copyWith(imagePath: path).toMap(includeImagePath: true),
      );
    } catch (e) {
      showErrorMessage('Could not import image');
    }
  }

  Future<void> capture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }
    try {
      final file = await _cameraController!.takePicture();
      final path = file.path;
      if (path.isNotEmpty) {
        await _disposeCamera();
        Get.toNamed(
          Routes.REFINE_SCAN,
          arguments: _vaultArgs.copyWith(imagePath: path).toMap(includeImagePath: true),
        );
      }
    } catch (e) {
      showErrorMessage('Capture failed');
    }
  }

  Future<void> retryPermission() async {
    await _disposeCamera();
    await _initCamera();
  }

  Future<void> openAppSettingsForCamera() async {
    await openAppSettings();
  }
}
