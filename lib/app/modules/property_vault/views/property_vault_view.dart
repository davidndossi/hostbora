import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/property_vault_controller.dart';

const _vaultTeal = Color(0xFF1C6E64);

class PropertyVaultView extends BaseView<PropertyVaultController> {
  PropertyVaultView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.propertyVault,
      isBackButtonEnabled: false,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          icon: const Icon(Icons.more_vert_outlined)
        )
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(context),
          const SizedBox(height: 24),
          _buildRecentlyAccessed(context),
          const SizedBox(height: 24),
          _buildMainDirectories(context),
          const SizedBox(height: 20),
          _buildVaultSyncedCard(context),
        ],
      ),
    );
  }

  @override
  Widget? floatingActionButton() => _buildFab(Get.context!);

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: TextField(
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search vault documents...',
          hintStyle: TextStyle(
            color: AppColors.designPlaceholder,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 22,
            color: AppColors.designPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRecentlyAccessed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENTLY ACCESSED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: _vaultTeal,
              ),
            ),
            TextButton(
              onPressed: controller.viewAllRecent,
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _vaultTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.recentlyAccessed.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = controller.recentlyAccessed[index];
              return _RecentCard(item: item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainDirectories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAIN DIRECTORIES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _vaultTeal,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: controller.directories
              .map(
                (dir) => _DirectoryCard(
                  item: dir,
                  onTap: () => controller.openDirectory(dir),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildVaultSyncedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _vaultTeal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done, size: 32, color: _vaultTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vault Synced',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _vaultTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All documents are encrypted and secured.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: controller.onFabTap,
      backgroundColor: _vaultTeal,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final RecentDocumentItem item;

  const _RecentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.lightGreyColor.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppValues.radius_12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: AppColors.textColorSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.length > 18
                        ? '${item.name.substring(0, 15)}...'
                        : item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final VaultDirectoryItem item;
  final VoidCallback onTap;

  const _DirectoryCard({required this.item, required this.onTap});

  static const _iconByDir = {
    'Legal Documents': Icons.folder_outlined,
    'Tax Records': Icons.receipt_long_outlined,
    'Property Manuals': Icons.menu_book_outlined,
    'Guest IDs': Icons.badge_outlined,
    'Maintenance': Icons.build_outlined,
    'Property Photos': Icons.photo_library_outlined,
  };

  IconData get _icon =>
      _DirectoryCard._iconByDir[item.name] ?? Icons.folder_outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _vaultTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.itemCount,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.modified,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ],
              ),
              if (item.isLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.textColorSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
