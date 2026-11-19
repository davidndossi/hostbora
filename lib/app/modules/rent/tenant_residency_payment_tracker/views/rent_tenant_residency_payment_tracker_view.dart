import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/form_surface_colors.dart';

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
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(controller.tenantsScreenTitle);

  @override
  Widget body(BuildContext context) {
    final currency = Get.find<CurrencyService>();

    return Obx(() {
      final noTenants = controller.tenants.isEmpty;
      if (controller.tenantsInitialLoading.value && noTenants) {
        return const TenancyInsightsScreenSkeleton();
      }

      // Every control on this screen reads from the tenant list — collection
      // rate, exports, search, the finance window. With no tenants they all
      // render as zeroes and dead inputs, which reads as a broken screen
      // rather than a new one. Show the one action that applies instead.
      if (noTenants) {
        return _noTenantsYet(context);
      }

      return RefreshIndicator(
        onRefresh: controller.loadTenants,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSw ? 'Muhtasari' : 'Overview',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSw
                    ? 'Makusanyo na mikataba kwa mali hii'
                    : 'Collections and leases for this property',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 16),
              _reportsActionsRow(context),
              const SizedBox(height: 18),
              _searchRow(context),
              const SizedBox(height: 18),
              _financeWindowToggle(context),
              const SizedBox(height: 12),
              Obx(() {
                final list = controller.filteredTenants;
                // Tenants exist but none match. Previously this collapsed to
                // an empty Column, so the screen looked identical to having no
                // tenants at all and gave no hint that a filter caused it.
                if (list.isEmpty) {
                  return _noMatches(context);
                }
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

  /// Shown in place of the whole dashboard when the property has no tenants.
  ///
  /// Scrollable rather than a centred [Column] so pull-to-refresh still works
  /// here — a tenant added on another device should be reachable without
  /// leaving the screen.
  Widget _noTenantsYet(BuildContext context) {
    final tokens = context.tokens;
    final scoped = controller.filterPropertyTitle;

    return RefreshIndicator(
      onRefresh: controller.loadTenants,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.people_outline,
                size: 44,
                color: tokens.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              scoped.isEmpty
                  ? (_isSw ? 'Hakuna mpangaji bado' : 'No tenants yet')
                  : (_isSw
                      ? 'Hakuna mpangaji katika $scoped'
                      : 'No tenants in $scoped yet'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isSw
                  ? 'Ongeza mpangaji ili kuanza kufuatilia kodi, mikataba na makusanyo. Takwimu zote kwenye skrini hii zitajaa zenyewe.'
                  : 'Add a tenant to start tracking rent, leases and collections. Every figure on this screen fills in from there.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            rentPrimaryButton(
              label: _isSw ? 'Ongeza mpangaji' : 'Add tenant',
              icon: Icons.person_add_alt_outlined,
              onPressed: controller.addTenant,
            ),
            const SizedBox(height: 14),
            Text(
              _isSw
                  ? 'Unaweza kuongeza wapangaji wengi kwa mali hii.'
                  : 'You can add more than one tenant to this property.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when tenants exist but the active search or filters exclude all of
  /// them. Deliberately distinct from [_noTenantsYet]: the fix here is to
  /// widen the filter, not to add anybody.
  Widget _noMatches(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined, size: 32, color: tokens.textMuted),
          const SizedBox(height: 12),
          Text(
            _isSw ? 'Hakuna mpangaji anayelingana' : 'No tenants match',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSw
                ? 'Wapangaji ${controller.tenants.length} wamefichwa na utafutaji au vichujio vilivyowekwa.'
                : '${controller.tenants.length} tenants are hidden by the current search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: controller.clearSearchAndFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            style: TextButton.styleFrom(foregroundColor: tokens.accent),
            label: Text(
              _isSw ? 'Ondoa vichujio' : 'Clear filters',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Exports and schedule — kept out of the app bar to avoid crowding the title.
  Widget _reportsActionsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final fg = isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1F2937);

    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool emphasize = false,
    }) {
      return Material(
        color: emphasize ? _teal.withValues(alpha: isDark ? 0.28 : 0.08) : chipBg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: emphasize
                    ? _teal.withValues(alpha: 0.45)
                    : border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: emphasize ? _teal : fg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: emphasize ? _teal : fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Ripoti na usafirishaji' : 'Reports & exports',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        Scrollbar(
          controller: controller.reportsScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: controller.reportsScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Bulk messaging used to be the screen's FAB. Each tenant card
                // now carries its own message icon, so this keeps the
                // everyone-at-once case reachable without making it the
                // default — which it was, purely by being the only option.
                Obx(
                  () => chip(
                    icon: Icons.forum_outlined,
                    label: _isSw
                        ? 'SMS kwa ${controller.filteredTenants.length}'
                        : 'Message ${controller.filteredTenants.length}',
                    onTap: controller.openSendSmsForFilteredTenants,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => chip(
                    icon: controller.whatsappScheduleEnabled.value
                        ? Icons.schedule_send
                        : Icons.schedule_outlined,
                    label: _isSw ? 'Ratiba' : 'Schedule',
                    emphasize: controller.whatsappScheduleEnabled.value,
                    onTap: () => _openScheduleSheet(context),
                  ),
                ),
                const SizedBox(width: 8),
                chip(
                  icon: Icons.picture_as_pdf_outlined,
                  label: _isSw ? 'PDF (chumba)' : 'Apartment PDF',
                  onTap: controller.openApartmentPdfReports,
                ),
                const SizedBox(width: 8),
                chip(
                  icon: Icons.table_chart_outlined,
                  label: _isSw ? 'Excel: kodi' : 'Excel: rent',
                  onTap: controller.exportCustomerRentDetailsExcel,
                ),
                const SizedBox(width: 8),
                chip(
                  icon: Icons.summarize_outlined,
                  label: _isSw ? 'Excel: muhtasari' : 'Excel: summary',
                  onTap: controller.exportCustomerRentTenantSummaryExcel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget? floatingActionButton() {
    return Obx(() {
      // Hidden only on the empty state, which already puts the same action in
      // the middle of the screen as its primary button.
      if (controller.tenants.isEmpty) return const SizedBox.shrink();
      return FloatingActionButton.extended(
        onPressed: controller.addTenant,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: Text(_isSw ? 'Ongeza mpangaji' : 'Add tenant',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700
          ),
        ),
      );
    });
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
              fontWeight: FontWeight.w700,
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
                const Icon(Icons.hourglass_bottom_outlined, size: 20, color: _teal),
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
    final rate = controller.collectionRatePct.clamp(0, 100);
    final collectionColor = rate >= 80
        ? (isDark ? const Color(0xFF69F0AE) : const Color(0xFF1B7A4E))
        : rate >= 50
            ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFFB7791F))
            : (isDark ? const Color(0xFFFF8A80) : const Color(0xFF8B3A3A));
    final onSchedule = controller.tenants.where((e) => e.onSchedule).length;
    final total = controller.tenants.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSw ? 'Kiwango cha makusanyo' : 'Collection rate',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: labelMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: controller.collectionRatePctLabel,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: collectionColor,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: '%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: collectionColor.withValues(alpha: 0.85),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSw
                          ? '$onSchedule kati ya $total wako kwa ratiba'
                          : '$onSchedule of $total on schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: labelMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: total == 0 ? 0 : (rate / 100).clamp(0.0, 1.0),
                        strokeWidth: 7,
                        backgroundColor: dividerColor.withValues(alpha: 0.65),
                        color: collectionColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      total == 0 ? '—' : '${rate.round()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: collectionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (rate / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: dividerColor.withValues(alpha: 0.55),
              color: collectionColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: dividerColor.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.home_work_outlined, size: 18, color: activeLeaseColor),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'Mikataba hai' : 'Active leases',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${controller.activeLeasesCount}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: activeLeaseColor,
                  height: 1,
                ),
              ),
            ],
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
    final borderColor = tokens.border.withValues(alpha: isDark ? 0.7 : 1);
    final filterIconColor = isDark ? tokens.accent : _teal;

    Widget iconBtn({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
      bool active = false,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: active
              ? _teal.withValues(alpha: isDark ? 0.22 : 0.08)
              : fieldBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? _teal.withValues(alpha: 0.45)
                      : borderColor,
                ),
              ),
              child: Icon(icon, size: 20, color: filterIconColor),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Obx(
            () => TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: TextStyle(
                color: inputColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: isDark ? tokens.accent : _teal,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fieldBg,
                hintText: _isSw ? 'Tafuta wapangaji' : 'Search tenants',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search_outlined, color: hintColor, size: 20),
                suffixIcon: controller.searchQuery.value.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _isSw ? 'Futa' : 'Clear',
                        icon: Icon(Icons.close_outlined, size: 18, color: hintColor),
                        onPressed: controller.clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF5EC9C3) : _teal,
                    width: 1.2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        iconBtn(
          icon: Icons.compare_arrows_outlined,
          tooltip: _isSw ? 'Linganisha' : 'Compare',
          onTap: () => _openCompareSheet(context),
        ),
        const SizedBox(width: 8),
        Obx(() {
          final active = controller.hasActiveFilters;
          return iconBtn(
            icon: Icons.tune_outlined,
            tooltip: _isSw ? 'Chuja' : 'Filter',
            active: active,
            onTap: controller.onFilterPressed,
          );
        }),
      ],
    );
  }

  Widget _financeWindowToggle(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final selected = controller.financeWindow.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? tokens.elevatedSurface : tokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _windowChip(
                label: _isSw ? 'Kipindi cha mkataba' : 'Tenure period',
                icon: Icons.calendar_today_outlined,
                selected: selected == TenantFinanceWindow.tenure,
                onTap: () =>
                    controller.setFinanceWindow(TenantFinanceWindow.tenure),
              ),
            ),
            Expanded(
              child: _windowChip(
                label: _isSw ? 'Muda wote' : 'All-time',
                icon: Icons.all_inclusive,
                selected: selected == TenantFinanceWindow.allTime,
                onTap: () =>
                    controller.setFinanceWindow(TenantFinanceWindow.allTime),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _windowChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _teal : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : _teal,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Per-tenant message action, sitting on the tenant's own card.
  ///
  /// This replaced a single screen-level FAB that messaged every filtered
  /// tenant at once. Choosing a recipient by first narrowing a filter is a
  /// roundabout way to text one person, and it made the common case — chasing
  /// one late tenant — the hardest thing on the screen.
  ///
  /// Greyed rather than hidden when the tenant has no phone number: a missing
  /// icon reads as a layout glitch, where a dimmed one with a tooltip explains
  /// itself and hints at the fix.
  Widget _tenantSmsButton(TenantInsight t, {required bool isDark}) {
    final hasPhone = t.phoneNumber.trim().isNotEmpty;
    final tint = hasPhone
        ? _teal.withValues(alpha: isDark ? 0.22 : 0.1)
        : Colors.grey.withValues(alpha: isDark ? 0.18 : 0.1);
    final glyph = hasPhone
        ? _teal
        : (isDark ? Colors.white38 : Colors.grey.shade500);

    return Tooltip(
      message: hasPhone
          ? (_isSw ? 'Tuma ujumbe kwa ${t.name}' : 'Message ${t.name}')
          : (_isSw ? 'Hakuna namba ya simu' : 'No phone number on file'),
      child: Material(
        color: tint,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasPhone ? () => controller.openSendSmsForTenant(t) : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.chat_bubble_outline, size: 18, color: glyph),
          ),
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

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: tokens.border.withValues(alpha: isDark ? 0.7 : 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: isDark ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: primaryText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              t.onSchedule
                                  ? _onScheduleBadge(isDark: isDark)
                                  : _statusLegend(isDark: isDark),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.propertyLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // _tenantSmsButton(t, isDark: isDark),
                    // const SizedBox(width: 2),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: expanded
                          ? (_isSw ? 'Funga maelezo' : 'Hide details')
                          : (_isSw ? 'Onyesha maelezo' : 'Show details'),
                      onPressed: () => controller.toggleTenantCardExpanded(t.id),
                      icon: AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_outlined,
                          color: tertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    Text(
                      currency.formatBase(t.paidAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                    Text(
                      '  /  ${currency.formatBase(t.totalAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tertiaryText,
                      ),
                    ),
                    const Spacer(),
                    _tenantSmsButton(t, isDark: isDark),
                    const SizedBox(width: 2),
                  ],
                ),
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => controller.openTenantLedger(t),
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal.withValues(alpha: isDark ? 0.22 : 0.1),
                          foregroundColor: _teal,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: Text(
                          _isSw ? 'Angalia mpangaji' : 'View tenant',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => controller.toggleTenantForComparison(t.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: BorderSide(
                          color: controller.isTenantSelectedForComparison(t.id)
                              ? _teal
                              : tokens.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        controller.isTenantSelectedForComparison(t.id)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                      ),
                      label: Text(
                        _isSw ? 'Linganisha' : 'Compare',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    fontWeight: FontWeight.w700,
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
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
          fontWeight: FontWeight.w700,
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
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
