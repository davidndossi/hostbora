import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../core/widget/skeleton_presets.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_residency_payment_tracker_controller.dart';

/// **Tenancy Insights** — overview metrics, search, tenant residency cards, FAB, bottom nav.
class RentTenantResidencyPaymentTrackerView
    extends RentBaseView<RentTenantResidencyPaymentTrackerController> {
  RentTenantResidencyPaymentTrackerView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _teal = Color(0xFF004D40);

  @override
  Color pageBackgroundColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF8F7F4);
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(controller.tenantsScreenTitle);

  @override
  Widget body(BuildContext context) {
    final currency = Get.find<CurrencyService>();

    return Obx(() {
      if (controller.tenantsInitialLoading.value && controller.tenants.isEmpty) {
        return const TenancyInsightsScreenSkeleton();
      }

      return RefreshIndicator(
        onRefresh: controller.loadTenants,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bodyActionsRow(context),
              const SizedBox(height: 12),
              Text(
                _isSw ? 'Muhtasari' : 'Overview',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              _overviewMetricsCard(context),
              Obx(() {
                final snap = controller.propertyPrincipal.value;
                if (snap == null || !snap.hasChartData) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _propertyPrincipalCard(context, snap, currency),
                );
              }),
              const SizedBox(height: 18),
              _searchRow(context),
              const SizedBox(height: 18),
              _financeWindowToggle(context),
              const SizedBox(height: 12),
              Obx(() {
                final list = controller.filteredTenants;
                return Column(
                  children: list
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _tenantCard(t, currency),
                        ),
                      )
                      .toList(),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _bodyActionsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Zana' : 'Tools',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Obx(
          () => IconButton(
            tooltip: _isSw ? 'Ratiba ya WhatsApp' : 'WhatsApp schedule',
            onPressed: () => _openScheduleSheet(context),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              controller.whatsappScheduleEnabled.value
                  ? Icons.schedule_send
                  : Icons.schedule_outlined,
              color: controller.whatsappScheduleEnabled.value
                  ? _teal
                  : scheme.onSurface,
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: _isSw ? 'Zaidi' : 'More',
          color: tokens.cardBackground,
          onSelected: (value) async {
            switch (value) {
              case 'export_details':
                await controller.exportCustomerRentDetailsExcel();
                break;
              case 'export_summary':
                await controller.exportCustomerRentTenantSummaryExcel();
                break;
              // TEMP: Meta WhatsApp send disabled until Meta issues are cleared.
              // case 'send_now':
              //   await controller.sendScheduledReportNowViaWhatsApp();
              //   break;
              case 'schedule':
                _openScheduleSheet(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export_details',
              child: Text(
                _isSw
                    ? 'Pakua Excel: Rent details'
                    : 'Download Excel: Rent details',
              ),
            ),
            PopupMenuItem(
              value: 'export_summary',
              child: Text(
                _isSw
                    ? 'Pakua Excel: Tenant summary'
                    : 'Download Excel: Tenant summary',
              ),
            ),
            // TEMP: Meta WhatsApp send disabled until Meta issues are cleared.
            // PopupMenuItem(
            //   value: 'send_now',
            //   child: Text(
            //     _isSw
            //         ? 'Tuma kupitia WhatsApp sasa'
            //         : 'Send via WhatsApp now',
            //   ),
            // ),
            PopupMenuItem(
              value: 'schedule',
              child: Text(
                _isSw
                    ? 'Ratiba ya WhatsApp (wiki/mwezi)'
                    : 'WhatsApp schedule (weekly/monthly)',
              ),
            ),
          ],
          icon: Icon(Icons.more_vert, color: scheme.onSurface),
        ),
      ],
    );
  }

  @override
  Widget? floatingActionButton() {
    return FloatingActionButton(
      onPressed: controller.openSendSmsForFilteredTenants,
      child: const Icon(Icons.chat_bubble_outline),
    );
  }

  Future<void> _openScheduleSheet(BuildContext context) async {
    var enabled = controller.whatsappScheduleEnabled.value;
    var frequency = controller.whatsappScheduleFrequency.value;
    var template = controller.whatsappScheduleTemplate.value;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSw
                          ? 'Ratiba ya Ripoti ya Excel WhatsApp'
                          : 'WhatsApp Excel Report Schedule',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.scheduleSubtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      value: enabled,
                      onChanged: (v) => setState(() => enabled = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _isSw
                            ? 'Washa kutuma ripoti mara kwa mara'
                            : 'Enable periodic report sharing',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TenantReportFrequency>(
                      initialValue: frequency,
                      decoration: InputDecoration(
                        labelText: _isSw ? 'Mzunguko' : 'Frequency',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: TenantReportFrequency.weekly,
                          child: Text(_isSw ? 'Kila wiki' : 'Weekly'),
                        ),
                        DropdownMenuItem(
                          value: TenantReportFrequency.monthly,
                          child: Text(_isSw ? 'Kila mwezi' : 'Monthly'),
                        ),
                      ],
                      onChanged: enabled
                          ? (v) => setState(() => frequency = v ?? frequency)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TenancyExcelTemplate>(
                      initialValue: template,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _isSw ? 'Aina ya Excel' : 'Excel template',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: TenancyExcelTemplate.customerRentDetails,
                          child: Text(
                            'customer_rent_details_template.csv',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              TenancyExcelTemplate.customerRentTenantSummary,
                          child: Text(
                            'customer_rent_tenant_summary_template.csv',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: enabled
                          ? (v) => setState(() => template = v ?? template)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await controller.saveWhatsAppSchedule(
                            enabled: enabled,
                            frequency: frequency,
                            template: template,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(_isSw ? 'Hifadhi Ratiba' : 'Save Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _propertyPrincipalCard(
    BuildContext context,
    PropertyPrincipalSnapshot snap,
    CurrencyService currency,
  ) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = tokens.cardBackground;
    final labelMuted = tokens.textMuted;
    final total = snap.principalCost + snap.maintenanceCost + snap.incomeGenerated;
    if (total <= 0) return const SizedBox.shrink();

    double pct(double v) => (v / total * 100).clamp(0.1, 100);
    final sections = <PieChartSectionData>[
      if (snap.principalCost > 0)
        PieChartSectionData(
          value: snap.principalCost,
          color: _teal,
          title: '${pct(snap.principalCost).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      if (snap.maintenanceCost > 0)
        PieChartSectionData(
          value: snap.maintenanceCost,
          color: const Color(0xFF5D4037),
          title: '${pct(snap.maintenanceCost).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      if (snap.incomeGenerated > 0)
        PieChartSectionData(
          value: snap.incomeGenerated,
          color: const Color(0xFF26A69A),
          title: '${pct(snap.incomeGenerated).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Mtaji dhidi ya mapato' : 'Principal vs income',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: labelMuted,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: sections,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (snap.principalCost > 0)
                        _principalLegendLine(
                          labelMuted,
                          _isSw ? 'Mtaji' : 'Principal',
                          currency.formatBase(snap.principalCost),
                          _teal,
                        ),
                      if (snap.maintenanceCost > 0) ...[
                        const SizedBox(height: 6),
                        _principalLegendLine(
                          labelMuted,
                          _isSw ? 'Matengenezo' : 'Maintenance',
                          currency.formatBase(snap.maintenanceCost),
                          const Color(0xFF5D4037),
                        ),
                      ],
                      if (snap.incomeGenerated > 0) ...[
                        const SizedBox(height: 6),
                        _principalLegendLine(
                          labelMuted,
                          _isSw ? 'Mapato' : 'Income',
                          currency.formatBase(snap.incomeGenerated),
                          const Color(0xFF26A69A),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3D3A) : const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_bottom_rounded, size: 20, color: _teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    snap.breakEvenLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _principalLegendLine(
    Color labelMuted,
    String label,
    String amount,
    Color dot,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label · $amount',
            style: TextStyle(fontSize: 11, color: labelMuted),
          ),
        ),
      ],
    );
  }

  Widget _overviewMetricsCard(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = tokens.cardBackground;
    final labelMuted = tokens.textMuted;
    final dividerColor = tokens.border;
    final shadowAlpha = isDark ? 0.32 : 0.04;
    final activeLeaseColor = isDark ? tokens.accent : _teal;
    final collectionColor = isDark
        ? const Color(0xFFFF8A80)
        : const Color(0xFF8B3A3A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'Mikataba hai' : 'Active leases',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600,
                    color: labelMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${controller.activeLeasesCount}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: activeLeaseColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 52, color: dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'Kiwango cha makusanyo' : 'Collection rate',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600,
                      color: labelMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.collectionRatePct}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: collectionColor,
                      height: 1,
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

  Widget _searchRow(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = tokens.cardBackground;
    final hintColor = tokens.textMuted;
    final inputColor = tokens.textPrimary;
    final borderSide = isDark ? BorderSide(color: tokens.border) : BorderSide.none;
    final filterIconColor = isDark ? tokens.accent : _teal.withValues(alpha: 0.85);

    return Row(
      children: [
        Expanded(
          child: Obx(
            () => TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: TextStyle(color: inputColor, fontSize: 14),
              cursorColor: isDark ? tokens.accent : _teal,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fieldBg,
                hintText: _isSw ? 'Tafuta wapangaji' : 'Search tenants',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
                suffixIcon: controller.searchQuery.value.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _isSw ? 'Futa' : 'Clear',
                        icon: Icon(Icons.clear, size: 20, color: hintColor),
                        onPressed: controller.clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: borderSide,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: borderSide,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: isDark
                      ? const BorderSide(color: Color(0xFF5EC9C3), width: 1.2)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _openCompareSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.compare_arrows_rounded, color: filterIconColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() {
          final active = controller.hasActiveFilters;
          return Material(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: controller.onFilterPressed,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: active
                          ? (isDark
                              ? const Color(0xFF5EC9C3)
                              : _teal)
                          : filterIconColor,
                    ),
                    if (active)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF5EC9C3)
                                : _teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _financeWindowToggle(BuildContext context) {
    return Obx(
      () => Center(
        child: SegmentedButton<TenantFinanceWindow>(
          segments: [
            ButtonSegment(
              value: TenantFinanceWindow.tenure,
              label: Text(
                _isSw ? 'Kipindi cha mkataba' : 'Tenure period',
                style: const TextStyle(fontSize: 14),
              ),
              icon: const Icon(Icons.date_range_outlined, size: 16),
            ),
            ButtonSegment(
              value: TenantFinanceWindow.allTime,
              label: Text(
                _isSw ? 'Muda wote' : 'All-time',
                style: const TextStyle(fontSize: 14),
              ),
              icon: const Icon(Icons.all_inclusive, size: 16),
            ),
          ],
          selected: {controller.financeWindow.value},
          onSelectionChanged: (set) {
            final next = set.first;
            controller.setFinanceWindow(next);
          },
        ),
      ),
    );
  }

  Widget _tenantCard(TenantInsight t, CurrencyService currency) {
    final pct = (t.leaseProgress * 100).round();
    final ctx = Get.context!;
    final tokens = ctx.tokens;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cardBg = tokens.cardBackground;
    final primaryText = tokens.textPrimary;
    final secondaryText = tokens.textSecondary;
    final tertiaryText = tokens.textMuted;
    final progressBg = isDark ? tokens.elevatedSurface : Colors.grey.shade200;

    return Obx(() {
      final expanded = controller.isTenantCardExpanded(t.id);

      return Material(
        color: cardBg,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.openTenantLedger(t),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 52,
                              height: 52,
                              color: _teal.withValues(alpha: 0.1),
                              alignment: Alignment.center,
                              child: Text(
                                t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _teal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.home_outlined,
                                      size: 15,
                                      color: tertiaryText,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        t.propertyLine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryText,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              t.onSchedule
                                  ? _onScheduleBadge(isDark: isDark)
                                  : _statusLegend(isDark: isDark),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: currency.formatBase(t.paidAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _teal,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / ${currency.formatBase(t.totalAmount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: tertiaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: expanded
                        ? (_isSw ? 'Funga maelezo' : 'Hide details')
                        : (_isSw ? 'Onyesha maelezo' : 'Show details'),
                    onPressed: () => controller.toggleTenantCardExpanded(t.id),
                    icon: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, color: tertiaryText),
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSw ? 'Muda wa ukaaji' : 'Stay duration',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tertiaryText,
                      ),
                    ),
                    Text(
                      t.totalStayLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_isSw ? 'Maendeleo ya mkataba' : 'Lease progress'} (${t.leasePeriodLabel})',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    Text(
                      _isSw ? '$pct% imekamilika' : '$pct% complete',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: t.leaseProgress,
                    minHeight: 8,
                    backgroundColor: progressBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isSw
                      ? 'Daftari la hali ya malipo (muda wa sasa)'
                      : 'Payment status ledger (current term)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tertiaryText,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: List.generate(
                      t.monthStatuses.length,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i < t.monthStatuses.length - 1 ? 6 : 0,
                          ),
                          child: _monthBox(
                            i + 1,
                            t.monthStatuses[i],
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _tenantIncomeExpensePie(t, currency, isDark: isDark),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.openTenantLedger(t),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(
                        _isSw ? 'Fungua daftari' : 'View ledger',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => controller.toggleTenantForComparison(t.id),
                    icon: Icon(
                      controller.isTenantSelectedForComparison(t.id)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    label: Text(
                      _isSw ? 'Linganisha' : 'Compare',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tenantIncomeExpensePie(
    TenantInsight t,
    CurrencyService currency, {
    required bool isDark,
  }) {
    final income = t.incomeForTenure.clamp(0, double.infinity).toDouble();
    final expense = t.expenseForTenure.clamp(0, double.infinity).toDouble();
    final hasAny = income > 0 || expense > 0;
    final incomeColor = const Color(0xFF00796B);
    final expenseColor = const Color(0xFFD84315);
    final tokens = Get.context!.tokens;
    final muted = tokens.textMuted;
    final pieBg = isDark ? tokens.cardBackground : const Color(0xFFF7F7F7);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pieBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: hasAny
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 1,
                      centerSpaceRadius: 20,
                      sections: [
                        PieChartSectionData(
                          value: income <= 0 ? 0.001 : income,
                          color: incomeColor,
                          title: '',
                          radius: 24,
                        ),
                        PieChartSectionData(
                          value: expense <= 0 ? 0.001 : expense,
                          color: expenseColor,
                          title: '',
                          radius: 24,
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      _isSw ? 'Hakuna data' : 'No data',
                      style: TextStyle(fontSize: 10, color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'INCOME vs EXPENSE (TENURE)' : 'INCOME vs EXPENSE (TENURE)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 7),
                _lineLegend(
                  color: incomeColor,
                  label: _isSw ? 'Mapato' : 'Income',
                  value: currency.formatBase(income.round()),
                ),
                const SizedBox(height: 4),
                _lineLegend(
                  color: expenseColor,
                  label: _isSw ? 'Matumizi' : 'Expenses',
                  value: currency.formatBase(expense.round()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineLegend({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _openCompareSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Obx(() {
          final selected = controller.comparedTenants;
          final currency = Get.find<CurrencyService>();
          final metrics = selected
              .map((t) => (tenant: t, metric: controller.compareMetricForTenant(t)))
              .toList(growable: false);
          final maxValue = metrics.fold<double>(
            1,
            (m, item) {
              final next = item.metric.income > item.metric.expense
                  ? item.metric.income
                  : item.metric.expense;
              return next > m ? next : m;
            },
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'Linganisha Wapangaji' : 'Compare Tenants',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(now.year - 5, 1, 1),
                              lastDate: DateTime(now.year + 2, 12, 31),
                              initialDateRange: controller.compareRangeStart.value != null &&
                                      controller.compareRangeEnd.value != null
                                  ? DateTimeRange(
                                      start: controller.compareRangeStart.value!,
                                      end: controller.compareRangeEnd.value!,
                                    )
                                  : null,
                              locale: const Locale('en', 'GB'),
                            );
                            if (picked != null) {
                              controller.setCompareRange(
                                start: picked.start,
                                end: picked.end,
                              );
                            }
                          },
                          icon: const Icon(Icons.tune, size: 16),
                          label: Text(
                            _isSw ? 'Chagua date range' : 'Pick date range',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: controller.clearCompareRange,
                        child: Text(_isSw ? 'Futa' : 'Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_isSw ? 'Range' : 'Range'}: ${controller.compareRangeLabel}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  if (selected.isEmpty)
                    Text(
                      _isSw
                          ? 'Chagua mpaka wapangaji 4 kwa kitufe cha Compare kwenye kadi.'
                          : 'Select up to 4 tenants using Compare on each card.',
                    )
                  else
                    ...metrics.map((item) {
                      final t = item.tenant;
                      final m = item.metric;
                      final incomeRatio = ((m.income / maxValue).clamp(0.0, 1.0)).toDouble();
                      final expenseRatio = maxValue <= 0
                          ? 0.0
                          : ((m.expense / maxValue).clamp(0.0, 1.0)).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_isSw ? 'Mapato' : 'Income'}: ${currency.formatBase(m.income.round())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            LinearProgressIndicator(
                              minHeight: 7,
                              value: incomeRatio,
                              color: const Color(0xFF00796B),
                              backgroundColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_isSw ? 'Matumizi' : 'Expenses'}: ${currency.formatBase(m.expense.round())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            LinearProgressIndicator(
                              minHeight: 7,
                              value: expenseRatio,
                              color: const Color(0xFFD84315),
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _monthBox(
    int monthIndex,
    ResidencyMonthStatus s, {
    required bool isDark,
  }) {
    late Color bg;
    late Color fg;
    switch (s) {
      case ResidencyMonthStatus.paid:
        bg = _teal;
        fg = Colors.white;
      case ResidencyMonthStatus.partial:
        bg = const Color(0xFFFFCDD2);
        fg = const Color(0xFF5D1A1A);
      case ResidencyMonthStatus.upcoming:
        final tokens = Get.context!.tokens;
        bg = isDark ? tokens.elevatedSurface : const Color(0xFFE8E8E8);
        fg = isDark ? tokens.textSecondary : Colors.grey.shade700;
    }
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'M$monthIndex',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _onScheduleBadge({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? _teal.withValues(alpha: 0.24)
            : _teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _isSw ? 'Katika ratiba' : 'On schedule',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _teal,
        ),
      ),
    );
  }

  Widget _statusLegend({required bool isDark}) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendDot(_teal, _isSw ? 'Imelipwa' : 'Paid', isDark: isDark),
        _legendDot(
          const Color(0xFFFFCDD2),
          _isSw ? 'Sehemu' : 'Partial',
          dark: true,
          isDark: isDark,
        ),
        _legendDot(
          isDark ? Get.context!.tokens.elevatedSurface : const Color(0xFFE8E8E8),
          _isSw ? 'Inakuja' : 'Upcoming',
          dark: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _legendDot(
    Color c,
    String label, {
    bool dark = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: dark
                ? (isDark ? const Color(0xFFB0B3BA) : Colors.grey.shade700)
                : _teal,
          ),
        ),
      ],
    );
  }
}
