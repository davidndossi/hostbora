import 'package:get/get.dart';

import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../controllers/add_document_controller.dart';

class AddDocumentBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VaultDocumentsStore>()) {
      Get.lazyPut<VaultDocumentsStore>(VaultDocumentsStore.new, fenix: true);
    }
    if (!Get.isRegistered<VaultDirectoriesStore>()) {
      Get.lazyPut<VaultDirectoriesStore>(VaultDirectoriesStore.new, fenix: true);
    }
    Get.lazyPut<AddDocumentController>(
      () => AddDocumentController(
        directoriesStore: Get.find<VaultDirectoriesStore>(),
        documentsStore: Get.find<VaultDocumentsStore>(),
      ),
    );
  }
}
