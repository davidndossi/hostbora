import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../listing_details/models/listing_activity_vm.dart';
import '../../rent_theme.dart';
import '../controllers/rent_listing_activity_log_controller.dart';

class RentListingActivityLogView extends RentBaseView<RentListingActivityLogController> {
  RentListingActivityLogView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F7F4);
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: controller.screenTitle,
      showLanguageToggle: false,
      showThemeToggle: false,
    );
  }

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? context.tokens.cardBackground : Colors.white;
    final titleColor = isDark ? Colors.white : RentTheme.navy;
    final muted = isDark ? const Color(0xFFAEAEB2) : RentTheme.muted;

    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return RefreshIndicator(
        onRefresh: controller.loadActivities,
        child: controller.activities.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      appLocalization.rentListingActivityLogEmpty,
                      style: TextStyle(fontSize: 15, color: muted),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: controller.activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _activityTile(
                    context,
                    controller.activities[index],
                    card,
                    titleColor,
                    muted,
                  );
                },
              ),
      );
    });
  }

  Widget _activityTile(
    BuildContext context,
    ListingActivityVm a,
    Color card,
    Color titleColor,
    Color muted,
  ) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: a.accentColor.withValues(alpha: 0.2),
              child: Icon(Icons.circle, size: 10, color: a.accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                  if (a.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      a.subtitle,
                      style: TextStyle(fontSize: 13, color: muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  a.trailing,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.timeLabel,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
