import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class RecentDocumentItem {
  final String name;
  final String timeAgo;

  const RecentDocumentItem({required this.name, required this.timeAgo});
}

class VaultDirectoryItem {
  final String name;
  final String itemCount;
  final String modified;
  final String route;
  final bool isLocked;

  const VaultDirectoryItem({
    required this.name,
    required this.itemCount,
    required this.modified,
    required this.route,
    this.isLocked = false,
  });
}

class PropertyVaultController extends BaseController {
  final searchQuery = ''.obs;

  final recentlyAccessed = <RecentDocumentItem>[
    const RecentDocumentItem(name: 'Rental_Agreement.pdf', timeAgo: '2 hours ago'),
    const RecentDocumentItem(name: 'Kitchen_Manual.png', timeAgo: '5 hours ago'),
    const RecentDocumentItem(name: 'Insurance_Policy_2024.pdf', timeAgo: '1 day ago'),
  ];

  final directories = <VaultDirectoryItem>[
    const VaultDirectoryItem(
      name: 'Legal Documents',
      itemCount: '12 items',
      modified: 'Modified Oct 12',
      route: Routes.LEGAL_DOCUMENTS,
    ),
    const VaultDirectoryItem(
      name: 'Tax Records',
      itemCount: '8 items',
      modified: 'Modified Oct 10',
      route: Routes.LEGAL_DOCUMENTS,
    ),
    const VaultDirectoryItem(
      name: 'Property Manuals',
      itemCount: '5 items',
      modified: 'Modified 2h ago',
      route: Routes.LEGAL_DOCUMENTS,
    ),
    const VaultDirectoryItem(
      name: 'Guest IDs',
      itemCount: '24 items',
      modified: 'Modified Oct 11',
      route: Routes.LEGAL_DOCUMENTS,
      isLocked: true,
    ),
    const VaultDirectoryItem(
      name: 'Maintenance',
      itemCount: '45 items',
      modified: 'Modified Oct 9',
      route: Routes.LEGAL_DOCUMENTS,
    ),
    const VaultDirectoryItem(
      name: 'Property Photos',
      itemCount: '32 items',
      modified: 'Modified Oct 8',
      route: Routes.LEGAL_DOCUMENTS,
    ),
  ];

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void viewAllRecent() {
    Get.toNamed(Routes.LEGAL_DOCUMENTS);
  }

  void openDirectory(VaultDirectoryItem dir) {
    Get.toNamed(dir.route);
  }

  void onFabTap() {
    // TODO: add document or folder
    Get.toNamed(Routes.LEGAL_DOCUMENTS);
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        break; // Vault - current
      case 2:
        // TODO: Messages
        break;
      case 3:
        Get.offAllNamed(Routes.SETTINGS);
        break; // Profile
    }
  }
}
