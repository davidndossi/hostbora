import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../core/widget/hub_insight_banner.dart';
import '../../../../routes/app_pages.dart';
import '../controllers/rent_hub_controller.dart';

/// Evergreen Estate — Rent hub dashboard (monthly performance, listings, bottom nav).
abstract class _HubTheme {
  static const Color teal = Color(0xFF005F5F);
  static const Color navy = Color(0xFF1B2838);
  static const Color muted = Color(0xFF6B7280);
  static const Color cardCream = Color(0xFFF0EDE6);
  static const Color salmon = Color(0xFFFDE2D9);
  static const Color expenseRed = Color(0xFFB91C1C);
  static const Color chartMutedBar = Color(0xFFC5D4D6);
}

class RentHubView extends RentBaseView<RentHubController> {
  RentHubView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
        appBarTitleText: appLocalization.dashboard,
        isBackButtonEnabled: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () {
                      final ws = controller.workspaceContext.currentWorkspace.value;
                      final activeLabel = ws == 'rent' ? 'RENT' : 'BnB';
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _HubTheme.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    'RENT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.6,
                      color: _HubTheme.teal,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('|', style: TextStyle(color: _HubTheme.muted, fontSize: 13)),
                  ),
                  InkWell(
                    onTap: () async {
                      await controller.workspaceContext.switchWorkspace('bnb');
                      // Return to BnB shell so bottom navigation is rebuilt.
                      Get.offAllNamed(Routes.MAIN);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'BnB',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.4,
                          color: _HubTheme.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }

  @override
  Widget body(BuildContext context) {
    // final themeController = Get.find<ThemeController>();
    return Obx(
      () => RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HubInsightBanner(),
              _financialOverviewHeader(context),
              const SizedBox(height: 14),
              _portfolioKpiGrid(context),
              const SizedBox(height: 14),
              _hostDashboard(context),
              const SizedBox(height: 12),
              _netProfitCard(),
              const SizedBox(height: 12),
              _incomeExpenseRow(context),
              // const SizedBox(height: 12),
              // _managePaymentsShortcut(context),
              const SizedBox(height: 20),
              _revenueChartCard(context),
              const SizedBox(height: 16),
              // _managementTipsCard(),
              // const SizedBox(height: 12),
              // _conciergeSupportCard(),
              // const SizedBox(height: 24),
              // _listingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _portfolioKpiGrid(BuildContext context) {
    final s = _HubSurfaces.of(context);
    final card = s.cardBg();
    final muted = s.muted;
    final incomeColor = s.accent;
    final leaseColor = s.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final arrearsColor = s.isDark ? const Color(0xFFFF8A80) : const Color(0xFFB91C1C);

    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  context,
                  card: card,
                  label: _isSw ? 'Mapato ya mwezi' : 'Monthly income',
                  value: controller.monthlyIncomeLabel,
                  valueColor: incomeColor,
                  icon: Icons.payments_outlined,
                  onTap: controller.openManagePayments,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  context,
                  card: card,
                  label: _isSw ? 'Ukaaji' : 'Occupancy',
                  value: controller.occupancyLabel,
                  valueColor: incomeColor,
                  icon: Icons.pie_chart_outline_rounded,
                  onTap: controller.openTenancyInsights,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  context,
                  card: card,
                  label: _isSw ? 'Mikataba hai' : 'Active leases',
                  value: controller.activeLeasesLabel,
                  valueColor: leaseColor,
                  icon: Icons.assignment_ind_outlined,
                  onTap: controller.openTenancyInsights,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  context,
                  card: card,
                  label: _isSw ? 'Deni (arrears)' : 'Arrears',
                  value: controller.totalArrearsLabel,
                  valueColor: arrearsColor,
                  icon: Icons.warning_amber_rounded,
                  onTap: controller.openTenancyInsights,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSw
                ? 'Makadirio kwa mali zote (mwezi huu)'
                : 'Portfolio totals across all properties (this month)',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required Color card,
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: valueColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: _HubSurfaces.of(context).muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _financialOverviewHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalization.financialOverview.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _HubTheme.muted.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${appLocalization.monthly} ${appLocalization.performance}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: _isSw ? 'Msaada' : 'Help',
          onPressed: () => Get.toNamed(
            Routes.HELP_CENTER,
            parameters: {'workspace': 'rent'},
          ),
          icon: const Icon(Icons.help_outline_rounded, size: 22),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: controller.openAddExpense,
          icon: const Icon(Icons.payment, size: 16),
          label: Text(
            appLocalization.addExpense.replaceFirst(' ', '\n'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(92, 48),
            minimumSize: const Size(92, 48),
            maximumSize: const Size(92, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: controller.openAddIncome,
          icon: const Icon(Icons.payments, size: 16),
          label: Text(
            appLocalization.addIncome.replaceFirst(' ', '\n'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(92, 48),
            minimumSize: const Size(92, 48),
            maximumSize: const Size(92, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _netProfitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: _HubTheme.teal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _HubTheme.teal.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8E8C8).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: Colors.green.shade800),
                    const SizedBox(width: 4),
                    Text(
                      controller.profitTrendLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${appLocalization.monthly} ${appLocalization.netProfit}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.netProfitLabel,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _managePaymentsShortcut(BuildContext context) {
    final s = _HubSurfaces.of(context);
    return Material(
      color: s.cardBg(cream: true),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Get.toNamed(Routes.RENT_MANAGE_PAYMENTS),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: s.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appLocalization.managePayments,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: s.accent,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: s.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _incomeExpenseRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _metricTile(
            context,
            label: appLocalization.income,
            value: controller.totalIncomeLabel,
            circleColor: isDark ? const Color(0xFF1A3D3D) : const Color(0xFFD8EFEE),
            icon: Icons.arrow_upward_rounded,
            iconColor: _HubSurfaces.of(context).accent,
            onTap: () => Get.toNamed(Routes.RENT_MANAGE_PAYMENTS),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricTile(
            context,
            label: appLocalization.expenses,
            value: controller.expensesLabel,
            circleColor: isDark ? const Color(0xFF3D2520) : const Color(0xFFF5D5CE),
            icon: Icons.arrow_downward_rounded,
            iconColor: isDark ? const Color(0xFFFFAB91) : const Color(0xFF9A3412),
            onTap: () => Get.toNamed(Routes.RENT_MANAGE_EXPENSES),
          ),
        ),
      ],
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color circleColor,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final s = _HubSurfaces.of(context);
    final cardBg = s.cardBg(cream: true);
    final labelColor = s.labelMuted;
    final valueColor = s.title;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _revenueChartCard(BuildContext context) {
    final inc = controller.chartIncome;
    final exp = controller.chartExpense;
    final rawMaxY = [
      for (var i = 0; i < inc.length; i++) inc[i] > exp[i] ? inc[i] : exp[i],
    ].reduce((a, b) => a > b ? a : b);
    final maxY = rawMaxY <= 0 ? 1.0 : rawMaxY * 1.15;
    final gridInterval = (maxY / 4).clamp(0.25, double.infinity);

    final s = _HubSurfaces.of(context);
    final cardBg = s.cardBg();
    final titleColor = s.title;
    final gridLineColor = s.gridLine;
    final axisMuted = s.labelMuted;
    final shadowAlpha = s.isDark ? 0.28 : 0.05;
    final expenseBarColor = s.isDark ? const Color(0xFF5C6368) : _HubTheme.chartMutedBar;
    final incomeBarColor = s.incomeBar;
    final expenseLegendDot =
        s.isDark ? const Color(0xFFFF8A80) : _HubTheme.expenseRed;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.performanceTrends,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(context, incomeBarColor, appLocalization.income),
              const SizedBox(width: 16),
              _legendDot(context, expenseLegendDot, appLocalization.expenses),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: gridInterval,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: gridInterval,
                      getTitlesWidget: (v, m) => Text(
                        v == v.roundToDouble() ? v.toInt().toString() : '',
                        style: TextStyle(fontSize: 9, color: axisMuted.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= RentHubController.days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            RentHubController.days[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: axisMuted.withValues(alpha: 0.95),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: exp[i],
                        color: expenseBarColor,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: inc[i],
                        color: incomeBarColor,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color c, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white.withValues(alpha: 0.72) : _HubTheme.navy.withValues(alpha: 0.75);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _hostDashboard(BuildContext context) {
    final s = _HubSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: s.cardBg(cream: true),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: controller.openHostDashboard,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.dashboard_outlined, color: s.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isSw ? 'Dashibodi ya Mwenyeji' : 'Host Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: s.accent,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: s.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context, ThemeController themeController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _HubSurfaces.of(context).border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
            size: 22,
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.colorPrimaryLight : AppColors.colorPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dark theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          Obx(
                () => Switch(
              value: themeController.isDarkMode.value,
              onChanged: (_) => themeController.toggleTheme(),
              activeTrackColor: AppColors.colorPrimaryLight,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.colorPrimary;
                return AppColors.designInputBorder;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _managementTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _HubTheme.salmon,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Management Excellence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _HubTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay ahead with proactive maintenance, clear tenant communication, and data-driven rent reviews.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _HubTheme.navy.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: controller.onReadManagementTips,
            child: Text(
              'Read Management Tips',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _HubTheme.teal,
                decoration: TextDecoration.underline,
                decorationColor: _HubTheme.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conciergeSupportCard() {
    return Material(
      color: _HubTheme.cardCream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: controller.onConciergeSupportTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline_rounded, color: _HubTheme.teal, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concierge Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _HubTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available 24/7 for you',
                      style: TextStyle(fontSize: 12, color: _HubTheme.muted.withValues(alpha: 0.95)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your portfolio',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: _HubTheme.muted.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                appLocalization.myProperties,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _HubTheme.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.onViewAllProperties();
                Get.toNamed(Routes.RENT_LISTING_ANALYTICS_DASHBOARD);
              },
              child: Text(
                appLocalization.viewAll,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _HubTheme.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = controller.listings[i];
              return _ListingCard(
                item: item,
                onTap: () {
                  controller.onListingTap(item);
                  Get.toNamed(
                    Routes.RENT_LISTING_DETAILS,
                    parameters: {
                      if (item.hubId.trim().isNotEmpty) 'id': item.hubId.trim(),
                      if (item.title.trim().isNotEmpty) 'title': item.title.trim(),
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item, required this.onTap});

  final RentHubListingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  children: [
                    Image.asset(
                      item.imageAsset,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 110,
                        color: _HubTheme.cardCream,
                        child: const Icon(Icons.home_work_outlined, color: _HubTheme.muted, size: 40),
                      ),
                    ),
                    if (item.occupied)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Occupied',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _HubTheme.muted.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _HubTheme.navy,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly rent',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: _HubTheme.muted.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                item.monthlyRentLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _HubTheme.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: _HubTheme.muted, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubSurfaces {
  const _HubSurfaces._(this.context);

  factory _HubSurfaces.of(BuildContext context) => _HubSurfaces._(context);

  final BuildContext context;

  AppThemeTokens get tokens => context.tokens;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color cardBg({bool cream = false}) =>
      isDark ? tokens.cardBackground : (cream ? _HubTheme.cardCream : Colors.white);

  Color get muted => isDark ? tokens.textSecondary : _HubTheme.muted;

  Color get labelMuted =>
      isDark ? tokens.textMuted : _HubTheme.muted.withValues(alpha: 0.95);

  Color get accent => isDark ? tokens.accent : _HubTheme.teal;

  Color get title => isDark ? tokens.textPrimary : _HubTheme.navy;

  Color get gridLine => isDark ? tokens.border : const Color(0xFFE5E2DC);

  Color get border => isDark ? tokens.border : AppColors.designInputBorder;

  Color get incomeBar => isDark ? tokens.accent : _HubTheme.teal;
}
