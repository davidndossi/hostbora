import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../controllers/notifications_controller.dart';


class NotificationsView extends BaseView<NotificationsController> {
  NotificationsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.menu, color: AppColors.colorPrimary),
      ),
      title: const Text(
        'The Concierge',
        style: TextStyle(
          color: AppColors.colorPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 36,
          height: 1.1,
        ),
      ),
      titleSpacing: 0,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.search, color: Colors.black54),
        ),
        SizedBox(width: 16),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.notifications, color: AppColors.colorPrimary),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.notificationsLength.value == 0) {
            return _buildEmptyState();
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
                      color: notification.delivered == true ? Colors.black38 : Colors.red,
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
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 22),
          SizedBox(
            height: 290,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFEFE8).withValues(alpha: 0.4),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF8F8F3).withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 72,
                    color: Color(0xFFA6D4D2),
                  ),
                ),
                Positioned(
                  right: 36,
                  bottom: 42,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF6E8E4).withValues(alpha: 0.85),
                    ),
                    child: const Icon(Icons.spa, color: Color(0xFF7A3C2D), size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'All Quiet Here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1D),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You're all caught up. We'll let you know\nwhen something important needs your\nattention.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.65,
              color: Color(0xFF3A3A38),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.returnToDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'RETURN TO DASHBOARD',
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            'EVERGREEN ESTATE IDENTITY',
            style: TextStyle(
              color: Color(0xFF9B9B97),
              letterSpacing: 2.2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 4, height: 48, color: const Color(0xFFBEDDDD)),
        ],
      ),
    );
  }
}
