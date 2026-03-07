import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class DocumentScannerController extends BaseController {
  final flashOn = false.obs;
  final autoCaptureOn = true.obs;

  void close() => Get.back();

  void toggleFlash() {
    flashOn.value = !flashOn.value;
    // TODO: control device torch when camera is integrated
  }

  void toggleAutoCapture() {
    autoCaptureOn.value = !autoCaptureOn.value;
  }

  void importFromGallery() async {
    // TODO: use file_picker or image_picker to pick image, then navigate to refine
    Get.toNamed(Routes.REFINE_SCAN);
  }

  void capture() {
    // TODO: when camera is integrated, pass captured image path
    Get.toNamed(Routes.REFINE_SCAN);
  }

  void batchMode() {
    // TODO: enable batch capture flow
    autoCaptureOn.value = false;
  }
}
