import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class RecentDocumentItem {
  final String name;
  final String timeAgo;

  const RecentDocumentItem({required this.name, required this.timeAgo});
}

class VaultDirectoryItem {
  final String directoryId;
  final String name;
  final String itemCount;
  final String modified;
  final bool isLocked;

  const VaultDirectoryItem({
    required this.directoryId,
    required this.name,
    required this.itemCount,
    required this.modified,
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
      directoryId: 'legal',
      name: 'Legal Documents',
      itemCount: '12 items',
      modified: 'Modified Oct 12',
    ),
    const VaultDirectoryItem(
      directoryId: 'tax',
      name: 'Tax Records',
      itemCount: '8 items',
      modified: 'Modified Oct 10',
    ),
    const VaultDirectoryItem(
      directoryId: 'manuals',
      name: 'Property Manuals',
      itemCount: '5 items',
      modified: 'Modified 2h ago',
    ),
    const VaultDirectoryItem(
      directoryId: 'guest_ids',
      name: 'Guest IDs',
      itemCount: '24 items',
      modified: 'Modified Oct 11',
      isLocked: true,
    ),
    const VaultDirectoryItem(
      directoryId: 'maintenance',
      name: 'Maintenance',
      itemCount: '45 items',
      modified: 'Modified Oct 9',
    ),
    const VaultDirectoryItem(
      directoryId: 'photos',
      name: 'Property Photos',
      itemCount: '32 items',
      modified: 'Modified Oct 8',
    ),
  ];

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void viewAllRecent() {
    Get.toNamed(Routes.DOCUMENTS);
  }

  void openDirectory(VaultDirectoryItem dir) {
    Get.toNamed(
      Routes.DOCUMENTS,
      arguments: {
        'directoryId': dir.directoryId,
        'directoryName': dir.name,
      },
    );
  }

  void onFabTap() {
    Get.toNamed(Routes.DOCUMENTS);
  }
}
