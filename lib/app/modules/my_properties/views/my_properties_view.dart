import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';
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
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const DefaultScreenSkeleton();
            }
            if (controller.properties.isEmpty) {
              return Center(
                child: Text(
                  _t(context, en: 'No properties', sw: 'Hakuna mali'),
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: controller.properties.length,
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = controller.properties[index];
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

  @override
  Widget? floatingActionButton() => FloatingActionButton(
    onPressed: () => controller.addProperty(),
    backgroundColor: AppColors.designAccent,
    child: const Icon(Icons.add, size: 28),
  );

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
                child: IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    listing.isFavorite ? Icons.favorite : Icons.favorite_border,
                    // color: Colors.white,
                    size: 26,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _StatusBadge(status: listing.status),
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

class _StatusBadge extends StatelessWidget {
  final PropertyStatus status;

  const _StatusBadge({required this.status});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  Widget build(BuildContext context) {
    final isReady = status == PropertyStatus.ready;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isReady ? AppColors.colorSuccessGreen : AppColors.colorYellow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check : Icons.cleaning_services,
            size: 16,
            color: isReady ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            isReady
                ? _t(context, en: 'Ready', sw: 'Tayari')
                : _t(context, en: 'Cleaning', sw: 'Usafishaji'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isReady ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
