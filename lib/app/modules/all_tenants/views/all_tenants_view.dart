import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/module_default_text_scope.dart';
import '../controllers/all_tenants_controller.dart';

const _bnbColor = Color(0xFF0D7377);
const _rentColor = Color(0xFF4F46E5);

class AllTenantsView extends GetView<AllTenantsController> {
  const AllTenantsView({super.key});

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
          appBarTitleText: _t(en: 'All Tenants', sw: 'Wapangaji Wote'),
          isBackButtonEnabled: true,
        ),
        body: Column(
          children: [
            _SearchBar(isSw: _isSw, controller: controller),
            _CategoryFilterRow(isSw: _isSw, controller: controller, c: c, theme: theme),
            _StatusFilterRow(isSw: _isSw, controller: controller, c: c, theme: theme),
            Expanded(child: _TenantList(isSw: _isSw, controller: controller, c: c, theme: theme)),
          ],
        ),
      ),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isSw, required this.controller});

  final bool isSw;
  final AllTenantsController controller;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final radius = BorderRadius.circular(AppValues.radius_12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          style: TextStyle(color: c.headline, fontSize: 14),
          decoration: InputDecoration(
            hintText: isSw
                ? 'Tafuta jina, mali, nambari…'
                : 'Search name, property, phone…',
            hintStyle: TextStyle(color: c.hint, fontSize: 14),
            prefixIcon: Icon(Icons.search, size: 20, color: c.hint),
            suffixIcon: controller.searchQuery.value.isEmpty
                ? null
                : IconButton(
                    tooltip: isSw ? 'Futa' : 'Clear',
                    icon: Icon(Icons.clear, size: 20, color: c.hint),
                    onPressed: controller.clearSearch,
                  ),
            // Override global InputDecorationTheme (light theme forces white fill).
            filled: true,
            fillColor: c.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.colorPrimary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category filter (All / BnB / Rent) ────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.isSw,
    required this.controller,
    required this.c,
    required this.theme,
  });

  final bool isSw;
  final AllTenantsController controller;
  final FormSurfaceColors c;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.categoryFilter.value;
      final all = controller.allItems.length;
      final bnb = controller.bnbCount;
      final rent = controller.rentCount;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            _CategoryChip(
              label: isSw ? 'Wote ($all)' : 'All ($all)',
              isSelected: selected == TenantCategoryFilter.all,
              color: AppColors.designAccent,
              onTap: () =>
                  controller.setCategoryFilter(TenantCategoryFilter.all),
              c: c,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: isSw ? 'BnB ($bnb)' : 'BnB Guests ($bnb)',
              isSelected: selected == TenantCategoryFilter.bnb,
              color: _bnbColor,
              onTap: () =>
                  controller.setCategoryFilter(TenantCategoryFilter.bnb),
              c: c,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: isSw ? 'Kodi ($rent)' : 'Rent Tenants ($rent)',
              isSelected: selected == TenantCategoryFilter.rent,
              color: _rentColor,
              onTap: () =>
                  controller.setCategoryFilter(TenantCategoryFilter.rent),
              c: c,
              theme: theme,
            ),
          ],
        ),
      );
    });
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.c,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final FormSurfaceColors c;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (c.isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (c.isDark
                    ? theme.colorScheme.outlineVariant
                    : AppColors.designInputBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (c.isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.textColorPrimary),
          ),
        ),
      ),
    );
  }
}

// ─── Status filter (All / Active / Past) ──────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.isSw,
    required this.controller,
    required this.c,
    required this.theme,
  });

  final bool isSw;
  final AllTenantsController controller;
  final FormSurfaceColors c;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.statusFilter.value;

      Widget chip(String label, TenantStatusFilter value, Color color) {
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => controller.setStatusFilter(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : (c.isDark
                        ? theme.colorScheme.outlineVariant
                        : AppColors.designInputBorder),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (c.isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.textColorSecondary),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Row(
          children: [
            chip(isSw ? 'Wote' : 'All', TenantStatusFilter.all,
                AppColors.designAccent),
            const SizedBox(width: 8),
            chip(isSw ? 'Wanaokaa' : 'Active',
                TenantStatusFilter.active, const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            chip(isSw ? 'Waliokaa' : 'Past',
                TenantStatusFilter.past, const Color(0xFF6B7280)),
          ],
        ),
      );
    });
  }
}

// ─── Tenant list ───────────────────────────────────────────────────────────────

class _TenantList extends StatelessWidget {
  const _TenantList({
    required this.isSw,
    required this.controller,
    required this.c,
    required this.theme,
  });

  final bool isSw;
  final AllTenantsController controller;
  final FormSurfaceColors c;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.allItems.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.filteredItems;
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 56, color: AppColors.textColorSecondary),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? (isSw
                        ? 'Hakuna wapangaji wanaofanana'
                        : 'No tenants match your search')
                    : (isSw
                        ? 'Hakuna wapangaji waliorekodiwa'
                        : 'No tenants recorded yet'),
                style: TextStyle(
                    fontSize: 15, color: AppColors.textColorSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadTenants,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _TenantCard(
            item: items[index],
            isSw: isSw,
            formatAmount: controller.formatAmount,
            c: c,
            theme: theme,
          ),
        ),
      );
    });
  }
}

// ─── Individual tenant card ────────────────────────────────────────────────────

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.item,
    required this.isSw,
    required this.formatAmount,
    required this.c,
    required this.theme,
  });

  final TenantListItem item;
  final bool isSw;
  final String Function(double) formatAmount;
  final FormSurfaceColors c;
  final ThemeData theme;

  Color get _categoryColor => item.isBnb ? _bnbColor : _rentColor;

  String get _categoryLabel =>
      item.isBnb ? 'BnB' : (isSw ? 'Kodi' : 'Rent');

  Color get _statusColor =>
      item.isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280);

  String get _statusLabel => item.isActive
      ? (isSw ? 'Anakaa' : 'Active')
      : (isSw ? 'Amemaliza' : 'Past');

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
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isBnb
                        ? Icons.hotel_outlined
                        : Icons.home_work_outlined,
                    size: 22,
                    color: _categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isEmpty
                            ? (isSw ? 'Asiyejulikana' : 'Unknown')
                            : item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.headline,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _categoryLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
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
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // ── Details row ────────────────────────────────────────────────
            Row(
              children: [
                _Detail(
                  icon: Icons.calendar_today_outlined,
                  label: isSw ? 'Alianza' : 'From',
                  value: item.leaseStartDisplay,
                  c: c,
                ),
                const SizedBox(width: 12),
                _Detail(
                  icon: Icons.event_outlined,
                  label: isSw ? 'Mwisho' : 'To',
                  value: item.leaseEndDisplay,
                  c: c,
                ),
                const SizedBox(width: 12),
                _Detail(
                  icon: Icons.attach_money,
                  label: isSw ? 'Kodi' : 'Rent',
                  value:
                      '${formatAmount(item.rentAmountValue)} / ${_shortFreq(item.rentFrequency)}',
                  c: c,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortFreq(String freq) {
    final f = freq.toLowerCase();
    if (f.contains('night')) return isSw ? 'usiku' : 'night';
    if (f.contains('week')) return isSw ? 'wiki' : 'wk';
    if (f.contains('year') || f.contains('annual')) return isSw ? 'mwaka' : 'yr';
    return isSw ? 'mwezi' : 'mo';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
  });

  final IconData icon;
  final String label;
  final String value;
  final FormSurfaceColors c;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppColors.textColorSecondary),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.headline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
