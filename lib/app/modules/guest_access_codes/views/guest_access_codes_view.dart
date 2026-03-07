import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/guest_access_codes_controller.dart';

const _accessTeal = Color(0xFF0A6A69);
const _screenBg = Color(0xFFF5F5F5);
const _scheduledAmber = Color(0xFFE5A500);

class GuestAccessCodesView extends BaseView<GuestAccessCodesController> {
  GuestAccessCodesView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => _screenBg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.guestAccessCodes,
      isCentered: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _accessTeal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
          ),
          child: Text(
            'TUYA CONNECTED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _accessTeal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveSection(context),
          const SizedBox(height: 24),
          _buildUpcomingSection(context),
          const SizedBox(height: 28),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildActiveSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE ACCESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textColorPrimary,
              ),
            ),
            Text(
              'Last synced: ${controller.lastSynced}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColorSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...controller.activeAccess.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccessCard(
              item: item,
              isActive: true,
              revealedGuestName: controller.revealedGuestName,
              onReveal: () => controller.toggleReveal(item),
              onShare: () => controller.shareCode(item),
              onCopy: () => controller.copyCode(item),
              onOptions: () => controller.openOptions(item),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING ACCESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...controller.upcomingAccess.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccessCard(
              item: item,
              isActive: false,
              revealedGuestName: controller.revealedGuestName,
              onReveal: () => controller.toggleReveal(item),
              onShare: () => controller.shareCode(item),
              onCopy: () => controller.copyCode(item),
              onOptions: () => controller.openOptions(item),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: controller.createCustomCode,
        icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white),
        label: const Text(
          'Create Custom Code',
          style: TextStyle(
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
    );
  }
}

class _AccessCard extends StatelessWidget {
  final GuestAccessItem item;
  final bool isActive;
  final Rx<String?> revealedGuestName;
  final VoidCallback onReveal;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onOptions;

  const _AccessCard({
    required this.item,
    required this.isActive,
    required this.revealedGuestName,
    required this.onReveal,
    required this.onShare,
    required this.onCopy,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? AppColors.colorSuccessGreen : _scheduledAmber;
    final statusLabel = isActive ? 'Active' : 'Scheduled';

    return Container(
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      item.guestName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                IconButton(
                  onPressed: () => onShare(),
                  icon: const Icon(Icons.share_outlined, size: 22),
                  color: AppColors.textColorPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                )
              else
                IconButton(
                  onPressed: onOptions,
                  icon: const Icon(Icons.more_vert, size: 22),
                  color: AppColors.textColorPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'ACCESS PIN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () {
              final revealed = revealedGuestName.value == item.guestName;
              final displayPin = revealed ? item.pinFull : '${item.pinVisible}•••';
              return Row(
                children: [
                  Text(
                    displayPin,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isActive)
                    GestureDetector(
                      onTap: onReveal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            revealed ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: _accessTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            revealed ? 'Hide' : 'Reveal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _accessTeal,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => onCopy(),
                      icon: const Icon(Icons.copy, size: 20),
                      color: AppColors.textColorPrimary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textColorSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.dateRange,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
