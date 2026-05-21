import 'package:get/get.dart';

import '../../../data/local/vault_documents_store.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../controllers/refine_scan_controller.dart';

class RefineScanBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VaultDocumentsStore>()) {
      Get.lazyPut<VaultDocumentsStore>(VaultDocumentsStore.new, fenix: true);
    }
    if (!Get.isRegistered<VaultRecentAccessStore>()) {
      Get.lazyPut<VaultRecentAccessStore>(VaultRecentAccessStore.new, fenix: true);
    }
    Get.lazyPut<RefineScanController>(
      () => RefineScanController(
        vaultStore: Get.find<VaultDocumentsStore>(),
        recentStore: Get.find<VaultRecentAccessStore>(),
      ),
    );
  }
}
