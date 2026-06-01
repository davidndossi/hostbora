import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/widget/guest_quick_actions_sheet.dart';
import '../../../core/widget/sync_status_chip.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/models/item_sync_status.dart';
import '../../../data/model/check_in_item.dart';
import '../controllers/all_bookings_controller.dart';
import '../../../../l10n/app_localizations.dart';

class AllBookingsView extends BaseView<AllBookingsController> {
  AllBookingsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, en: 'All Bookings', sw: 'Uhifadhi Wote'),
      isCentered: true,
      actions: [
        IconButton(
          tooltip: _t(context, en: 'Message guests', sw: 'Watumie wageni'),
          icon: const Icon(Icons.sms_outlined),
          onPressed: controller.messageGuestsWithPhones,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.initialLoading.value) {
        return const AllBookingsScreenSkeleton();
      }
      final list = controller.bookings;
      if (list.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.loadAllBookings(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _t(context, en: 'No bookings yet', sw: 'Bado hakuna uhifadhi'),
                    style: TextStyle(
                      fontSize: 16,
                      color: context.tokens.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.loadAllBookings(refresh: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: list.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = list[index];
            return _BookingCard(
              item: item,
              onTap: () => controller.openBookingDetails(item),
              onLongPress: () => showGuestQuickActionsSheet(
                context: context,
                item: item,
                onOpenBookingDetails: () => controller.openBookingDetails(item),
              ),
              onRetrySync: item.syncStatus == ItemSyncStatus.failed
                  ? () => controller.retryBookingSync(item)
                  : null,
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
  final VoidCallback? onLongPress;
  final VoidCallback? onRetrySync;

  const _BookingCard({
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onRetrySync,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textColor = tokens.textPrimary;
    final subTextColor = tokens.textSecondary;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                        color: subTextColor,
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
                          color: subTextColor,
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
                        if (item.showSyncBadge) ...[
                          SyncStatusChip(
                            status: item.syncStatus,
                            onRetry: onRetrySync,
                            compact: true,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (item.isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.bookingCancelledLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (item.isCancelled) const SizedBox(width: 4),
                        if (item.isCheckedOut)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textColorSecondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.bookingCheckedOut,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        if (item.isCheckedOut) const SizedBox(width: 4),
                        if (item.isConfirmed && !item.isInactive)
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
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
