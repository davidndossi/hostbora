import 'package:get/get.dart';

import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../controllers/documents_controller.dart';

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VaultDocumentsStore>(VaultDocumentsStore.new, fenix: true);
    if (!Get.isRegistered<VaultRecentAccessStore>()) {
      Get.lazyPut<VaultRecentAccessStore>(VaultRecentAccessStore.new, fenix: true);
    }
    Get.lazyPut<DocumentsController>(
      () => DocumentsController(
        vaultStore: Get.find<VaultDocumentsStore>(),
        recentStore: Get.find<VaultRecentAccessStore>(),
      ),
    );
  }
}
