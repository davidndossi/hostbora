import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/model/page_state.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../data/local/vault_recent_access_store.dart';
import '../controllers/property_vault_controller.dart';

const _vaultTeal = Color(0xFF1C6E64);

class PropertyVaultView extends BaseView<PropertyVaultController> {
  PropertyVaultView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.propertyVault
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.pageState == PageState.LOADING &&
          controller.directories.isEmpty) {
        return const DefaultScreenSkeleton();
      }
      if (controller.pageState == PageState.FAILED) {
        return _buildErrorState(context);
      }
      return RefreshIndicator(
        onRefresh: controller.loadVault,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      );
    });
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              appLocalization.vaultLoadError,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: controller.retry,
              child: Text(appLocalization.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? floatingActionButton() => _buildFab(Get.context!);

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: c.isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      child: TextField(
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: appLocalization.searchVaultDocuments,
          hintStyle: TextStyle(
            color: c.isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.designPlaceholder,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 22,
            color: c.isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.designPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
              appLocalization.recentlyAccessed,
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
                appLocalization.viewAll,
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
        Obx(() {
          if (controller.recentlyAccessed.isEmpty) {
            return SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  appLocalization.noRecentDocuments,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.recentlyAccessed.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = controller.recentlyAccessed[index];
                return _RecentCard(
                  item: item,
                  onTap: () => controller.openRecent(item),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainDirectories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization.mainDirectories,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _vaultTeal,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.directories.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  appLocalization.noVaultDirectories,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              ),
            );
          }
          return GridView.count(
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
                    itemCountText: _directoryItemCountLabel(dir.itemCount),
                    modifiedText:
                        '${appLocalization.vaultModified} ${controller.formatModified(dir.lastModified)}',
                    onTap: () => controller.openDirectory(dir),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildVaultSyncedCard(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (c.isDark ? theme.colorScheme.primary : _vaultTeal).withValues(
          alpha: 0.12,
        ),
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
                  appLocalization.vaultSynced,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _vaultTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appLocalization.vaultSyncedDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _directoryItemCountLabel(int count) {
    if (count == 0) return appLocalization.vaultNoItems;
    if (count == 1) return appLocalization.vaultOneItem;
    return appLocalization.vaultItemsCount(count);
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
  final VoidCallback onTap;

  const _RecentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    final name = item.entry.displayName;
    return SizedBox(
      width: 140,
      child: Material(
        color: c.isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.lightGreyColor.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppValues.radius_12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.entry.targetType == VaultRecentTargetType.directory
                        ? Icons.folder_outlined
                        : Icons.description_outlined,
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
                      name.length > 18 ? '${name.substring(0, 15)}...' : name,
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
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final VaultDirectoryItem item;
  final String itemCountText;
  final String modifiedText;
  final VoidCallback onTap;

  const _DirectoryCard({
    required this.item,
    required this.itemCountText,
    required this.modifiedText,
    required this.onTap,
  });

  static const _iconByDirId = {
    'legal': Icons.folder_outlined,
    'tax': Icons.receipt_long_outlined,
    'manuals': Icons.menu_book_outlined,
    'guest_ids': Icons.badge_outlined,
    'maintenance': Icons.build_outlined,
    'photos': Icons.photo_library_outlined,
  };

  IconData get _icon =>
      _DirectoryCard._iconByDirId[item.directoryId] ?? Icons.folder_outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Material(
      color: c.isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
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
                color: Colors.black.withValues(alpha: 0.06),
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
                    itemCountText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modifiedText,
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
