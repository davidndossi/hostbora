import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class RefineScanController extends BaseController {
  final blackAndWhiteOn = true.obs;
  final destinationFolder = 'Select folder'.obs;

  /// Optional image path/data passed from document scanner
  String? get scannedImagePath => Get.arguments as String?;

  void goBack() => Get.back();

  void rotate() {
    // TODO: rotate image 90°
  }

  void enhance() {
    // TODO: apply enhancement filter
  }

  void toggleBlackAndWhite() {
    blackAndWhiteOn.value = !blackAndWhiteOn.value;
  }

  void selectDestinationFolder() {
    // TODO: show folder picker or list (e.g. Legal Documents, Tax Records)
    destinationFolder.value = 'Legal Documents';
  }

  void retake() {
    Get.offNamed(Routes.DOCUMENT_SCANNER);
  }

  void saveToVault() {
    // TODO: save refined image to selected folder
    Get.offAllNamed(Routes.LEGAL_DOCUMENTS);
  }
}
