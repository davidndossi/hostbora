import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/property_listing_image.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/my_properties_controller.dart';

class MyPropertiesView extends BaseView<MyPropertiesController> {
  MyPropertiesView({super.key});

  

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.myProperties,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildFilterTabs(context),
        _buildWorkspaceModeFilter(context),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const DefaultScreenSkeleton();
            }
            final items = controller.displayProperties;
            if (items.isEmpty) {
              return _emptyState(theme, context);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = items[index];
                return _PropertyCard(
                  listing: p,
                  onFavorite: () => controller.toggleFavorite(p),
                  onManage: () => controller.manageProperty(p),
                  t: _t,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWorkspaceModeFilter(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    final isSw = (Get.locale?.languageCode ?? '') == 'sw';

    return Obx(() {
      final selected = controller.workspaceModeFilter.value;

      Widget chip(String label, String value, Color color) {
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => controller.setWorkspaceFilter(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color
                    : (c.isDark
                        ? theme.colorScheme.outlineVariant
                        : const Color(0xFFDDE1E7)),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (c.isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : const Color(0xFF64748B)),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            chip(isSw ? 'Zote' : 'All Modes', '', AppColors.designAccent),
            const SizedBox(width: 8),
            chip('BnB', 'bnb', const Color(0xFF0D7377)),
            const SizedBox(width: 8),
            chip(isSw ? 'Kodi' : 'Rent', 'rent', const Color(0xFF4F46E5)),
          ],
        ),
      );
    });
  }

  Widget _buildFilterTabs(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: List.generate(
            controller.filterLabels.length,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: index == controller.selectedFilterIndex.value
                    ? (c.isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : AppColors.colorWhite)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => controller.selectFilter(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Text(
                      controller.filterLabels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: index == controller.selectedFilterIndex.value
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'images/ic_building.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(Colors.grey.shade300, BlendMode.srcIn),
            ),
            const SizedBox(height: 16),
            Text(
              _t(context, en: 'No properties', sw: 'Hakuna mjengo'),
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyListing listing;
  final VoidCallback onFavorite;
  final VoidCallback onManage;
  final String Function(
    BuildContext context, {
    required String en,
    required String sw,
  })
  t;

  const _PropertyCard({
    required this.listing,
    required this.onFavorite,
    required this.onManage,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PropertyListingImage(
                imagePath: listing.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _FavoriteButton(
                  isFavorite: listing.isFavorite,
                  onTap: onFavorite,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _ModeBadge(mode: listing.mode),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    // color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.bed,
                      size: 18,
                      color: AppColors.textColorSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.unitSlots} ${t(context, en: 'Unit(s)', sw: 'V(k)itengo')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textColorSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textColorSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded, size: 18,
                      color: c.isDark
                          ? theme.colorScheme.primary
                          : AppColors.colorPrimaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${listing.activeTenants} ${t(context, en: 'Tenants', sw: 'Wapangaji')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: AppColors.designAccent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onManage,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t(context, en: 'Manage', sw: 'Simamia'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String mode;

  const _ModeBadge({required this.mode});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  ({Color bg, Color fg, IconData icon, String labelEn, String labelSw})
      _style() {
    switch (mode.trim().toLowerCase()) {
      case 'rent':
        return (
          bg: const Color(0xFF2563EB),
          fg: Colors.white,
          icon: Icons.key_outlined,
          labelEn: 'Rent',
          labelSw: 'Kodi',
        );
      case 'both':
        return (
          bg: const Color(0xFF7C3AED),
          fg: Colors.white,
          icon: Icons.swap_horiz_rounded,
          labelEn: 'Both',
          labelSw: 'Zote',
        );
      case 'bnb':
      default:
        return (
          bg: AppColors.colorSuccessGreen,
          fg: Colors.white,
          icon: Icons.house_outlined,
          labelEn: 'BnB',
          labelSw: 'BnB',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.fg),
          const SizedBox(width: 6),
          Text(
            _t(context, en: style.labelEn, sw: style.labelSw),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: style.fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Favourite button ──────────────────────────────────────────────────────────

/// A heart button that stays readable on any image background.
///
/// Technique: a slightly larger black icon is drawn beneath the white foreground
/// icon, acting as a natural outline/shadow. No packages, no async work.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isFavorite ? Icons.favorite : Icons.favorite_border;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow layer — slightly larger, semi-transparent black outline.
          Icon(icon, size: 30, color: Colors.black.withValues(alpha: 0.55)),
          // Foreground layer — white when not favorited, red when favorited.
          Icon(
            icon,
            size: 24,
            color: isFavorite ? Colors.redAccent : Colors.white,
          ),
        ],
      ),
    );
  }
}
