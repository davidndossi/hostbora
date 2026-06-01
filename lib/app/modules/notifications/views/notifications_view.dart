import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends BaseView<NotificationsController> {
  NotificationsView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: _t(context, en: 'Inbox', sw: 'Kikasha'),
  );

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const DefaultScreenSkeleton();
        }

        if (controller.notificationsLength.value == 0) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          itemCount: controller.notificationsLength.value,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return Card(
              child: ListTile(
                title: Text(notification.title ?? '-'),
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notification.delivered == true
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                subtitle: Text(notification.msg ?? '-'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    controller.deliverNotification(notification.id!);
                    controller.showNotification(notification);
                  },
                ),
                onTap: () {
                  controller.deliverNotification(notification.id!);
                  controller.showNotification(notification);
                },
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 22),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : const Color(0xFFEFEFE8))
                            .withValues(alpha: 0.4),
                  ),
                ),
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (isDark
                                ? theme.colorScheme.surfaceContainerHigh
                                : const Color(0xFFF8F8F3))
                            .withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.08,
                        ),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 46,
                    color: isDark
                        ? theme.colorScheme.primary
                        : const Color(0xFFA6D4D2),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.secondaryContainer
                          : const Color(0xFFE8D4CC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 20,
                      color: isDark
                          ? theme.colorScheme.onSecondaryContainer
                          : const Color(0xFF5C3D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(context, en: 'All Quiet Here', sw: 'Hakuna Kitu Kipya'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _t(
              context,
              en: "You're all caught up. We'll let you know\nwhen something important needs your\nattention.",
              sw: "Umesoma yote. Tutakujulisha\nkunapokuwa na jambo muhimu\nlinalohitaji umakini wako.",
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.65,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          Container(
            width: 4,
            height: 48,
            color: isDark ? theme.colorScheme.primary : const Color(0xFFBEDDDD),
          ),
        ],
      ),
    );
  }
}
