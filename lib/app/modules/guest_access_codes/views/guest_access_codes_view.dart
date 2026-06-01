import 'package:flutter/material.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/guest_access_codes_controller.dart';

const _accessTeal = Color(0xFF0A6A69);
const _screenBg = Color(0xFFF5F5F5);
const _scheduledAmber = Color(0xFFE5A500);

class GuestAccessCodesView extends BaseView<GuestAccessCodesController> {
  GuestAccessCodesView({super.key});

  

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).isDark ? Theme.of(context).colorScheme.surface : _screenBg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return CustomAppBar(
      appBarTitleText: appLocalization.guestAccessCodes,
      isCentered: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (c.isDark ? theme.colorScheme.primary : _accessTeal)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
          ),
          child: Text(
            _t(context, en: 'TUYA CONNECTED', sw: 'TUYA IMEUNGANISHWA'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.isDark ? theme.colorScheme.primary : _accessTeal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return RefreshIndicator(
        onRefresh: controller.loadAccessCodes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      );
    });
  }

  Widget _buildActiveSection(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t(context, en: 'ACTIVE ACCESS', sw: 'UFIKIAJI HAI'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: c.isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.textColorPrimary,
              ),
            ),
            Obx(
              () => Text(
              '${_t(context, en: 'Last synced', sw: 'Mara ya mwisho kusawazishwa')}: ${controller.lastSynced.value}',
              style: TextStyle(
                fontSize: 12,
                color: c.isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
              ),
            ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.activeAccess.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _t(
                  context,
                  en: 'No active guest access codes',
                  sw: 'Hakuna misimbo ya ufikiaji hai',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: c.isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.textColorSecondary,
                ),
              ),
            );
          }
          return Column(
            children: controller.activeAccess
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AccessCard(
                      item: item,
                      isActive: true,
                      revealedId: controller.revealedId,
                      onReveal: () => controller.toggleReveal(item),
                      onShare: () => controller.shareCode(item),
                      onCopy: () => controller.copyCode(item),
                      onOptions: () => controller.openOptions(item),
                      t: _t,
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'UPCOMING ACCESS', sw: 'UFIKIAJI UJAO'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: c.isDark
                ? theme.colorScheme.onSurface
                : AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.upcomingAccess.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _t(
                  context,
                  en: 'No upcoming access codes',
                  sw: 'Hakuna misimbo ya ufikiaji ujao',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: c.isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorSecondary,
                ),
              ),
            );
          }
          return Column(
            children: controller.upcomingAccess
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AccessCard(
                      item: item,
                      isActive: false,
                      revealedId: controller.revealedId,
                      onReveal: () => controller.toggleReveal(item),
                      onShare: () => controller.shareCode(item),
                      onCopy: () => controller.copyCode(item),
                      onOptions: () => controller.openOptions(item),
                      t: _t,
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: controller.createCustomCode,
        icon: const Icon(
          Icons.add_circle_outline,
          size: 22,
          color: Colors.white,
        ),
        label: Text(
          _t(context, en: 'Create Custom Code', sw: 'Tengeneza Msimbo Maalum'),
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
  final RxnString revealedId;
  final VoidCallback onReveal;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onOptions;
  final String Function(
    BuildContext context, {
    required String en,
    required String sw,
  })
  t;

  const _AccessCard({
    required this.item,
    required this.isActive,
    required this.revealedId,
    required this.onReveal,
    required this.onShare,
    required this.onCopy,
    required this.onOptions,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    final statusColor = isActive
        ? AppColors.colorSuccessGreen
        : _scheduledAmber;
    final statusLabel = isActive
        ? t(context, en: 'Active', sw: 'Hai')
        : t(context, en: 'Scheduled', sw: 'Imepangwa');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      item.guestName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
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
                        color: c.isDark
                            ? theme.colorScheme.onSurface
                            : AppColors.textColorPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                IconButton(
                  onPressed: () => onShare(),
                  icon: const Icon(Icons.share_outlined, size: 22),
                  color: c.isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                )
              else
                IconButton(
                  onPressed: onOptions,
                  icon: const Icon(Icons.more_vert, size: 22),
                  color: c.isDark
                      ? theme.colorScheme.onSurface
                      : AppColors.textColorPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t(context, en: 'ACCESS PIN', sw: 'NAMBARI YA UFIKIAJI'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Obx(() {
            final revealed = revealedId.value == item.id;
            final displayPin = revealed
                ? item.pinFull
                : '${item.pinVisible}•••';
            return Row(
              children: [
                Text(
                  displayPin,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: c.isDark
                        ? theme.colorScheme.onSurface
                        : AppColors.textColorPrimary,
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
                          color: c.isDark
                              ? theme.colorScheme.primary
                              : _accessTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          revealed
                              ? t(context, en: 'Hide', sw: 'Ficha')
                              : t(context, en: 'Reveal', sw: 'Onyesha'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.isDark
                                ? theme.colorScheme.primary
                                : _accessTeal,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => onCopy(),
                    icon: const Icon(Icons.copy, size: 20),
                    color: c.isDark
                        ? theme.colorScheme.onSurface
                        : AppColors.textColorPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            );
          }),
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
                    color: c.isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.textColorSecondary,
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
