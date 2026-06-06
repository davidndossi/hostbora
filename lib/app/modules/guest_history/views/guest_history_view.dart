import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/module_default_text_scope.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/guest_history_controller.dart';

const _bnbTeal = Color(0xFF0D7377);

class GuestHistoryView extends GetView<GuestHistoryController> {
  const GuestHistoryView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t({required String en, required String sw}) => _isSw ? sw : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);

    return ModuleDefaultTextScope(
      child: Scaffold(
        backgroundColor: c.isDark
            ? theme.colorScheme.surface
            : const Color(0xFFF6F8FA),
        appBar: CustomAppBar(
          appBarTitleText: _t(en: 'Guest History', sw: 'Historia ya Wageni'),
          isBackButtonEnabled: true,
        ),
        body: Column(
          children: [
            _buildSearchBar(context, c, theme),
            Expanded(child: _buildBody(context, c, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: c.isDark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: c.isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: _t(
              en: 'Search by guest, property…',
              sw: 'Tafuta mgeni, mali…',
            ),
            hintStyle: TextStyle(
              color: c.isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.designPlaceholder,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: c.isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.designPlaceholder,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FormSurfaceColors c,
    ThemeData theme,
  ) {
    return Obx(() {
      if (controller.isLoading.value && controller.allGuests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final guests = controller.filteredGuests;
      if (guests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 56,
                color: AppColors.textColorSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? _t(
                        en: 'No guests match your search',
                        sw: 'Hakuna wageni wanaofanana na utafutaji',
                      )
                    : _t(
                        en: 'No BnB guest stays recorded yet',
                        sw: 'Hakuna historia ya wageni bado',
                      ),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadGuestHistory,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: guests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _GuestCard(
              item: guests[index],
              isSw: _isSw,
              formatAmount: controller.formatAmount,
              c: c,
              theme: theme,
            );
          },
        ),
      );
    });
  }
}

class _GuestCard extends StatelessWidget {
  final GuestHistoryItem item;
  final bool isSw;
  final String Function(int) formatAmount;
  final FormSurfaceColors c;
  final ThemeData theme;

  const _GuestCard({
    required this.item,
    required this.isSw,
    required this.formatAmount,
    required this.c,
    required this.theme,
  });

  String _t({required String en, required String sw}) => isSw ? sw : en;

  Color get _statusColor {
    if (item.isFullyPaid) return const Color(0xFF16A34A);
    if (item.isPartial) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  String get _statusLabel {
    if (item.isFullyPaid) return _t(en: 'PAID', sw: 'AMELIPA');
    if (item.isPartial) return _t(en: 'PARTIAL', sw: 'SEHEMU');
    return _t(en: 'UNPAID', sw: 'HAJALIPA');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.isDark
          ? theme.colorScheme.surfaceContainerHigh
          : Colors.white,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: c.isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bnbTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 22,
                    color: _bnbTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.guestName.isEmpty
                            ? _t(en: 'Unknown Guest', sw: 'Mgeni Asiyejulikana')
                            : item.guestName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.headline,
                        ),
                      ),
                      if (item.propertyLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.unitLabel.isNotEmpty
                              ? '${item.propertyLabel} · ${item.unitLabel}'
                              : item.propertyLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.login,
                  label: _t(en: 'Check-in', sw: 'Kuingia'),
                  value: item.checkInDisplay,
                  c: c,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.logout,
                  label: _t(en: 'Check-out', sw: 'Kutoka'),
                  value: item.checkOutDisplay,
                  c: c,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.nights_stay_outlined,
                  label: _t(en: 'Nights', sw: 'Usiku'),
                  value: '${item.nights}',
                  c: c,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.attach_money,
                  label: _t(en: 'Due', sw: 'Deni'),
                  value: formatAmount(item.amountDue),
                  c: c,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.check_circle_outline,
                  label: _t(en: 'Paid', sw: 'Kilicholipwa'),
                  value: formatAmount(item.amountPaid),
                  valueColor: item.isFullyPaid
                      ? const Color(0xFF16A34A)
                      : null,
                  c: c,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final FormSurfaceColors c;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: AppColors.textColorSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? c.headline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
