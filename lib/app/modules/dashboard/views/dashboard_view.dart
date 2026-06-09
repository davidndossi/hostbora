import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../routes/app_pages.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends BaseView<DashboardController> {
  DashboardView({super.key});

  static const _chartPreviousColor = Color(0xFFE07A5F);

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.dashboard,
      isCentered: true
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const DefaultScreenSkeleton();
              }
              return RefreshIndicator(
                onRefresh: controller.loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _financialOverviewHeader(context),
                      const SizedBox(height: 14),
                      _netProfitCard(),
                      const SizedBox(height: 12),
                      _incomeExpenseRow(context),
                      const SizedBox(height: 20),
                      _buildPerformanceTrendsCard(context),
                      const SizedBox(height: 16),
                      _buildTotalRevenueCard(context),
                      const SizedBox(height: 12),
                      _buildMetricRow(context),
                      const SizedBox(height: 20),
                      _buildMonthlyGrowthSection(context),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _financialOverviewHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expanded(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         appLocalization.financialOverview.toUpperCase(),
        //         style: TextStyle(
        //           fontSize: 10,
        //           fontWeight: FontWeight.w700,
        //           letterSpacing: 1.2,
        //           color: context.tokens.textMuted.withValues(alpha: 0.9),
        //         ),
        //       ),
        //       const SizedBox(height: 4),
        //       Text(
        //         '${appLocalization.monthly} ${appLocalization.performance}',
        //         style: TextStyle(
        //           fontSize: 22,
        //           fontWeight: FontWeight.w700,
        //           height: 1.1,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(width: 8),
        // IconButton(
        //   tooltip: _t(context, 'Help', 'Msaada'),
        //   onPressed: () => Get.toNamed(
        //     Routes.HELP_CENTER,
        //     parameters: {'workspace': 'rent'},
        //   ),
        //   icon: const Icon(Icons.help_outline_rounded, size: 22),
        // ),
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
        color: AppColors.colorPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorPrimary.withValues(alpha: 0.25),
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
            iconColor: context.tokens.accent,
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
    final c = FormSurfaceColors.of(context);
    final cardBg = c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite;
    final labelColor = c.hint;
    final valueColor = c.headline;

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

    final c = FormSurfaceColors.of(context);
    final cardBg = c.card;
    final titleColor = c.headline;
    final gridLineColor = context.tokens.border;
    final axisMuted = c.hint;
    final shadowAlpha = c.isDark ? 0.28 : 0.05;
    final expenseBarColor = c.isDark ? const Color(0xFF5C6368) : Color(0xFFC5D4D6);
    final incomeBarColor = c.isDark ? context.tokens.border : AppColors.designInputBorder;
    final expenseLegendDot =
    c.isDark ? const Color(0xFFFF8A80) : Color(0xFFB91C1C);

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
              _legendDot1(context, incomeBarColor, appLocalization.income),
              const SizedBox(width: 16),
              _legendDot1(context, expenseLegendDot, appLocalization.expenses),
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
                        const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                        if (i < 0 || i >= days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[i],
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

  Widget _buildPerformanceTrendsCard(BuildContext context) {
    return Obx(() {
      final isIncome = controller.isIncomeSelected.value;
      final current = isIncome
          ? controller.currentTrendValues
          : controller.currentExpenseTrendValues;
      final previous = isIncome
          ? controller.previousTrendValues
          : controller.previousExpenseTrendValues;
      final currentSpots = current
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
      final previousSpots = previous
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
      return _performanceTrendsChart(context, currentSpots, previousSpots);
    });
  }

  Widget _performanceTrendsChart(
    BuildContext context,
    List<FlSpot> currentSpots,
    List<FlSpot> previousSpots,
  ) {
    final minY = 0.0;
    final maxY = 6.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 700,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card.copyWith(
            color: FormSurfaceColors.of(context).isDark
                ? const Color(0xFF1F1F1F)
                : AppColors.colorWhite,
            border: Border.all(
              color: FormSurfaceColors.of(context).isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: FormSurfaceColors.of(context).isDark ? 0.28 : 0.06,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(
                          context,
                          'Performance Trends',
                          'Mwelekeo wa Utendaji',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t(
                          context,
                          'Current vs. Previous Period',
                          'Kipindi hiki dhidi ya kilichopita',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _legendDot(AppColors.designAccent),
                      const SizedBox(width: 6),
                      Text(
                        _t(context, 'Current', 'Sasa'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _legendDot(_chartPreviousColor),
                      const SizedBox(width: 6),
                      Text(
                        _t(context, 'Previous', 'Kabla'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 180,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 3,
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1.5,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color:
                            (FormSurfaceColors.of(context).isDark
                                    ? Colors.white
                                    : AppColors.designInputBorder)
                                .withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i >= 0 &&
                                i < DashboardController.trendLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  DashboardController.trendLabels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.tokens.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: currentSpots,
                        isCurved: true,
                        color: AppColors.designAccent,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, data, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.designAccent,
                                strokeWidth: 2,
                                strokeColor: FormSurfaceColors.of(context).isDark
                                    ? const Color(0xFF1F1F1F)
                                    : AppColors.colorWhite,
                              ),
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: previousSpots,
                        isCurved: true,
                        color: _chartPreviousColor,
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 150),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _legendDot1(BuildContext context, Color c, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white.withValues(alpha: 0.72) : AppColors.colorPrimary.withValues(alpha: 0.75);
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

  Widget _buildTotalRevenueCard(BuildContext context) {
    return Obx(() {
      final isIncome = controller.isIncomeSelected.value;
      return _MetricCard(
        label: isIncome
            ? _t(context, 'Total Revenue', 'Jumla ya Mapato')
            : _t(context, 'Total Expenses', 'Jumla ya Gharama'),
        value: isIncome
            ? controller.totalRevenue.value
            : controller.totalExpenses.value,
        change: isIncome
            ? controller.totalRevenueChange.value
            : controller.totalExpensesChange.value,
        isPositive: isIncome
            ? controller.totalRevenueUp.value
            : controller.totalExpensesUp.value,
        fullWidth: true,
      );
    });
  }

  Widget _buildMetricRow(BuildContext context) {
    return Obx(() {
      final isIncome = controller.isIncomeSelected.value;
      return Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: isIncome
                  ? _t(
                      context,
                      'Avg. Daily Rate',
                      'Wastani wa Kiwango kwa Siku',
                    )
                  : _t(
                      context,
                      'Avg. Daily Expense',
                      'Wastani wa Gharama kwa Siku',
                    ),
              value: isIncome
                  ? controller.avgDailyRate.value
                  : controller.avgDailyExpense.value,
              change: isIncome
                  ? controller.avgDailyRateChange.value
                  : controller.avgDailyExpenseChange.value,
              isPositive: isIncome
                  ? controller.avgDailyRateUp.value
                  : controller.avgDailyExpenseUp.value,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: isIncome
                  ? _t(context, 'Net Profit', 'Faida Halisi')
                  : _t(context, 'Month Change', 'Mabadiliko ya Mwezi'),
              value: isIncome
                  ? controller.netProfit.value
                  : controller.totalExpensesChange.value,
              change: isIncome
                  ? controller.netProfitChange.value
                  : _t(context, 'vs. prev month', 'dhidi ya mwezi uliopita'),
              isPositive: isIncome
                  ? controller.netProfitUp.value
                  : controller.totalExpensesUp.value,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMonthlyGrowthSection(BuildContext context) {
    return Obx(() {
      final labels = controller.monthlyLabels;
      final valuesA = controller.monthlyValuesA;
      final valuesB = controller.monthlyValuesB;
      final isIncome = controller.isIncomeSelected.value;
      final values = isIncome ? valuesA : valuesB;
      final len = labels.length;
      if (len == 0) return const SizedBox.shrink();
      final groupBars = List.generate(len, (i) {
        final v = i < values.length ? values[i] : 0.0;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: v,
              color: AppColors.designAccent.withValues(alpha: 0.6),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
          showingTooltipIndicators: [],
        );
      });
      final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
      // Axis max must cover all bar heights; never cap below actual values (was clamping to 10).
      final maxY = maxVal <= 0
          ? 6.0
          : (maxVal * 1.08).clamp(6.0, double.infinity);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, 'Monthly Growth', 'Ukuaji wa Mwezi'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card.copyWith(
              color: FormSurfaceColors.of(context).isDark
                  ? const Color(0xFF1F1F1F)
                  : AppColors.colorWhite,
              border: Border.all(
                color: FormSurfaceColors.of(context).isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: FormSurfaceColors.of(context).isDark ? 0.28 : 0.06,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.tokens.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color:
                          (FormSurfaceColors.of(context).isDark
                                  ? Colors.white
                                  : AppColors.designInputBorder)
                              .withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: groupBars,
                ),
                duration: const Duration(milliseconds: 150),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final bool fullWidth;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final changeColor = isPositive
        ? AppColors.colorSuccessGreen
        : AppColors.paaYanguAlert;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        border: Border.all(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: c.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: changeColor,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
