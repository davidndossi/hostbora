import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/smart_access_controller.dart';

const _accessTeal = Color(0xFF0A6A69);
const _connectedGreen = Color(0xFF6CC76B);
const _screenBg = Color(0xFFF5F5F5);

class SmartAccessView extends BaseView<SmartAccessController> {
  SmartAccessView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => _screenBg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.smartAccess,
      isCentered: true,
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
        children: [
          _buildConnectedBadge(),
          const SizedBox(height: 28),
          _buildLockStatus(context),
          const SizedBox(height: 28),
          _buildActionButtons(context),
          const SizedBox(height: 28),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildConnectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _connectedGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _connectedGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'CONNECTED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _connectedGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockStatus(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessTeal.withOpacity(0.08),
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessTeal.withOpacity(0.12),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessTeal.withOpacity(0.18),
              ),
            ),
            Obx(
              () => Icon(
                controller.isLocked.value ? Icons.lock : Icons.lock_open,
                size: 56,
                color: _accessTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () => Text(
            controller.isLocked.value ? 'Locked' : 'Unlocked',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => Text(
            'UPDATED ${controller.lastUpdated}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColorSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.isLocked.value
                  ? controller.unlockDoor
                  : controller.lockDoor,
              icon: Icon(
                controller.isLocked.value ? Icons.lock_open : Icons.lock,
                size: 22,
                color: Colors.white,
              ),
              label: Text(
                controller.isLocked.value ? 'Unlock Door' : 'Lock Door',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accessTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: controller.generateGuestCode,
            icon: Icon(Icons.vpn_key, size: 22, color: _accessTeal),
            label: Text(
              'Generate Guest Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _accessTeal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _accessTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColorPrimary,
                ),
              ),
              TextButton(
                onPressed: controller.viewAllActivity,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _accessTeal,
                  ),
                ),
              ),
            ],
          ),
          ...controller.recentActivity.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppColors.textColorSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest: ${e.guestName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.detail} • ${e.time}',
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
        ],
      ),
    );
  }
}
