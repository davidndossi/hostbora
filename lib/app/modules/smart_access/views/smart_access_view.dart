import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/smart_access_controller.dart';

const _accessTeal = Color(0xFF0A6A69);
const _connectedGreen = Color(0xFF6CC76B);
const _screenBg = Color(0xFFF5F5F5);

class SmartAccessView extends BaseView<SmartAccessController> {
  SmartAccessView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      _isDark(context) ? Theme.of(context).colorScheme.surface : _screenBg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.smartAccess,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        children: [
          _buildConnectedBadge(context),
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

  Widget _buildConnectedBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _connectedGreen.withValues(alpha: 0.2),
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
            _t(context, en: 'CONNECTED', sw: 'IMEUNGANISHWA'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? theme.colorScheme.primary : _connectedGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockStatus(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
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
                color: _accessTeal.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessTeal.withValues(alpha: 0.12),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessTeal.withValues(alpha: 0.18),
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
            controller.isLocked.value
                ? _t(context, en: 'Locked', sw: 'Imefungwa')
                : _t(context, en: 'Unlocked', sw: 'Imefunguliwa'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.textColorPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => Text(
            '${_t(context, en: 'UPDATED', sw: 'IMESASISHWA')} ${controller.lastUpdated}',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.textColorSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
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
                controller.isLocked.value
                    ? _t(context, en: 'Unlock Door', sw: 'Fungua Mlango')
                    : _t(context, en: 'Lock Door', sw: 'Funga Mlango'),
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
            icon: Icon(
              Icons.vpn_key,
              size: 22,
              color: isDark ? theme.colorScheme.primary : _accessTeal,
            ),
            label: Text(
              _t(
                context,
                en: 'Generate Guest Code',
                sw: 'Tengeneza Msimbo wa Mgeni',
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? theme.colorScheme.primary : _accessTeal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? theme.colorScheme.primary : _accessTeal,
              ),
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
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Text(
                _t(
                  context,
                  en: 'Recent Activity',
                  sw: 'Shughuli za Hivi Karibuni',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorPrimary,
                ),
              ),
              TextButton(
                onPressed: controller.viewAllActivity,
                child: Text(
                  _t(context, en: 'View All', sw: 'Tazama Zote'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? theme.colorScheme.primary : _accessTeal,
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.recentActivity.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _t(
                    context,
                    en: 'No recent activity',
                    sw: 'Hakuna shughuli za hivi karibuni',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              );
            }
            return Column(
              children: controller.recentActivity.map(
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
                          '${_t(context, en: 'Guest', sw: 'Mgeni')}: ${e.guestName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? theme.colorScheme.onSurface
                                : AppColors.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.detail} • ${e.time}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
            );
          }),
        ],
      ),
    );
  }
}
