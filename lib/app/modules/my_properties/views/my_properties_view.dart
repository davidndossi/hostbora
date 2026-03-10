import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/my_properties_controller.dart';

class MyPropertiesView extends BaseView<MyPropertiesController> {
  MyPropertiesView({super.key});

  // @override
  // Color pageBackgroundColor(BuildContext context) => AppColors.designAccentDark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.myProperties,
      isCentered: true,
      isLight: true,
      isBackButtonEnabled: false,
      actions: [
        // IconButton(
        //   onPressed: controller.openFilter,
        //   icon: const Icon(Icons.tune),
        //   color: Colors.white,
        // ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        _buildFilterTabs(context),
        Expanded(
          child: Obx(
            () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: controller.properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = controller.properties[index];
                return _PropertyCard(
                  listing: p,
                  onFavorite: () => controller.toggleFavorite(p),
                  onManage: () => controller.manageProperty(p),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget? floatingActionButton() => FloatingActionButton(
    onPressed: controller.addProperty,
    backgroundColor: AppColors.designAccent,
    child: const Icon(Icons.add, size: 28),
  );


  Widget _buildFilterTabs(BuildContext context) {
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
                    ? AppColors.colorWhite
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
                            ? Colors.black
                            : Colors.black54,
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

  const _PropertyCard({
    required this.listing,
    required this.onFavorite,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                listing.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.designAccent,
                  child: const Icon(
                    Icons.home_work_outlined,
                    size: 48,
                    color: Colors.black54,
                  ),
                ),
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
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.textColorSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.rating}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textColorSecondary,
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
                    Text(
                      '\$${listing.pricePerNight}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.colorPrimaryLight,
                      ),
                    ),
                    Text(
                      ' / night',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: AppColors.designAccent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onManage,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Manage',
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

  @override
  Widget build(BuildContext context) {
    final isReady = status == PropertyStatus.ready;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isReady
            ? AppColors.colorSuccessGreen
            : AppColors.colorYellow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check : Icons.cleaning_services,
            size: 16,
            // color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isReady ? 'READY' : 'CLEANING',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
