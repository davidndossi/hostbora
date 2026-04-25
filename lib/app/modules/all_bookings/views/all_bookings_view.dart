import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/all_bookings_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';

class AllBookingsView extends BaseView<AllBookingsController> {
  AllBookingsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, en: 'All Bookings', sw: 'Uhifadhi Wote'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = controller.bookings;
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _t(context, en: 'No bookings yet', sw: 'Bado hakuna uhifadhi'),
              style: TextStyle(
                fontSize: 16,
                color: _isDark(context)
                    ? Colors.white54
                    : AppColors.textColorSecondary,
              ),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadAllBookings,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: list.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = list[index];
            return _BookingCard(
              item: item,
              onTap: () => controller.openBookingDetails(item),
            );
          },
        ),
      );
    });
  }
}

class _BookingCard extends StatelessWidget {
  final CheckInItem item;
  final VoidCallback? onTap;

  const _BookingCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textColorPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textColorSecondary;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: 120,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.lightGreyColor,
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textColorSecondary,
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      height: 100,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.lightGreyColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textColorSecondary,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.lightGreyColor,
                          backgroundImage: item.guestAvatarUrl.isNotEmpty
                              ? NetworkImage(item.guestAvatarUrl)
                              : null,
                          child: item.guestAvatarUrl.isEmpty
                              ? Text(
                                  item.guestName.isNotEmpty
                                      ? item.guestName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.guestName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isConfirmed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.colorPrimaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              Get.locale?.languageCode == 'sw'
                                  ? 'Imethibitishwa'
                                  : 'Confirmed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colorPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.propertyType,
                      style: TextStyle(fontSize: 14, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.dates,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white60 : AppColors.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
