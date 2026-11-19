import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/access/staff_access.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/overdue_occupants.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/module_default_text_scope.dart';
import '../../../data/local/service/currency_service.dart';
import '../controllers/home_controller.dart';

class OverduePeopleView extends GetView<HomeController> {
  const OverduePeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final c = FormSurfaceColors.of(context);
    return ModuleDefaultTextScope(
      child: Scaffold(
        backgroundColor: c.scaffold,
        appBar: CustomAppBar(
          appBarTitleText: isSw ? 'Wanaodaiwa' : 'Overdue',
          isBackButtonEnabled: true,
          isCentered: true,
        ),
        body: Obx(() {
          final rows = controller.visibleOverdueOccupants;
          if (rows.isEmpty) {
            return Center(
              child: Text(
                isSw
                    ? 'Hakuna wapangaji au wageni wanaodaiwa.'
                    : 'No overdue tenants or guests.',
                style: TextStyle(color: c.secondary),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              OverduePeopleListCard(
                rows: rows,
                onRowTap: controller.openOverdueOccupant,
                onWhatsApp: controller.whatsappOverdueOccupant,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class OverduePeopleHomeSection extends StatelessWidget {
  const OverduePeopleHomeSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    return Obx(() {
      controller.homeWorkspaceFilter.value;
      controller.overdueOccupants.length;
      if (!_canView(controller)) return const SizedBox.shrink();
      if (controller.snapshotSectionLoading.value) {
        return const SizedBox.shrink();
      }
      final preview = controller.overdueHomePreview;
      if (preview.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSw ? 'Wanaodaiwa' : 'Overdue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const OverduePeopleView()),
                  child: Text(
                    isSw ? 'Ona wote' : 'See all',
                    style: const TextStyle(
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OverduePeopleListCard(
              rows: preview,
              onRowTap: controller.openOverdueOccupant,
              onWhatsApp: controller.whatsappOverdueOccupant,
            ),
          ],
        ),
      );
    });
  }

  bool _canView(HomeController controller) {
    if (!Get.isRegistered<StaffAccessStore>()) return true;
    final access = Get.find<StaffAccessStore>();
    access.restricted.value;
    access.permissions.length;
    return access.allows(StaffPermissions.viewTenants) ||
        access.allows(StaffPermissions.viewBookings);
  }
}

class OverduePeopleListCard extends StatelessWidget {
  const OverduePeopleListCard({
    super.key,
    required this.rows,
    required this.onRowTap,
    required this.onWhatsApp,
  });

  final List<OverdueOccupant> rows;
  final ValueChanged<OverdueOccupant> onRowTap;
  final ValueChanged<OverdueOccupant> onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final isDark = c.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE8ECEF),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF0F2F4),
              ),
            _OverduePersonRow(
              row: rows[i],
              onTap: () => onRowTap(rows[i]),
              onWhatsApp: () => onWhatsApp(rows[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverduePersonRow extends StatelessWidget {
  const _OverduePersonRow({
    required this.row,
    required this.onTap,
    required this.onWhatsApp,
  });

  final OverdueOccupant row;
  final VoidCallback onTap;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final c = FormSurfaceColors.of(context);
    final cs = Get.find<CurrencyService>();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.colorPrimary.withValues(alpha: 0.12),
              child: Text(
                row.initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name.isEmpty
                        ? (isSw ? 'Asiyejulikana' : 'Unknown')
                        : row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.headline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.placeLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cs.formatNumber(row.amountOwed),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.headline,
                  ),
                ),
                const SizedBox(height: 4),
                _DaysBadge(days: row.daysOverdue, isSw: isSw),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'WhatsApp',
              onPressed: onWhatsApp,
              visualDensity: VisualDensity.compact,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.days, required this.isSw});

  final int days;
  final bool isSw;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final String label;
    if (days <= 0) {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFFF7E8);
      label = isSw ? 'Leo' : 'Today';
    } else if (days <= 7) {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFFF1D6);
      label = isSw ? 'Siku $days' : '$days d';
    } else {
      fg = const Color(0xFFB42318);
      bg = const Color(0xFFFEE4E2);
      label = isSw ? 'Siku $days' : '$days d';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
