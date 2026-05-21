import 'package:get/get.dart';

import '../../../data/local/vault_directories_store.dart';
import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../controllers/property_vault_controller.dart';

class PropertyVaultBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VaultDocumentsStore>()) {
      Get.lazyPut<VaultDocumentsStore>(VaultDocumentsStore.new, fenix: true);
    }
    if (!Get.isRegistered<VaultDirectoriesStore>()) {
      Get.lazyPut<VaultDirectoriesStore>(VaultDirectoriesStore.new, fenix: true);
    }
    if (!Get.isRegistered<VaultRecentAccessStore>()) {
      Get.lazyPut<VaultRecentAccessStore>(VaultRecentAccessStore.new, fenix: true);
    }
    Get.lazyPut<PropertyVaultController>(
      () => PropertyVaultController(
        directoriesStore: Get.find<VaultDirectoriesStore>(),
        documentsStore: Get.find<VaultDocumentsStore>(),
        recentStore: Get.find<VaultRecentAccessStore>(),
      ),
    );
  }
}
