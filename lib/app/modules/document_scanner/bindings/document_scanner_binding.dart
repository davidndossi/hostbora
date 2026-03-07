import 'package:get/get.dart';

import '../controllers/document_scanner_controller.dart';

class DocumentScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentScannerController>(DocumentScannerController.new);
  }
}
