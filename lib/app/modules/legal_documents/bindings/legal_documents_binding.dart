import 'package:get/get.dart';

import '../controllers/legal_documents_controller.dart';

class LegalDocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LegalDocumentsController>(LegalDocumentsController.new);
  }
}
