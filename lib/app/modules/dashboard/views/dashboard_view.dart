import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends BaseView<DashboardController> {
  DashboardView({super.key});

  static const _chartPreviousColor = Color(0xFFE07A5F);

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: controller.loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBnbOverviewSection(context),
                      _buildBnbWeeklyReportsSection(context),
                      _buildSegmentedToggle(context),
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

  Widget _buildBnbOverviewSection(BuildContext context) {
    return Obx(() {
      if (!controller.isBnbWorkspace.value) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, 'Overview', 'Muhtasari'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BnbOverviewCard(
                  title: appLocalization.bookings,
                  value: '${controller.bnbBookingsCount.value}',
                  onTap: controller.openBookings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BnbOverviewCard(
                  title: appLocalization.dashboardGuests,
                  value: '${controller.bnbGuestsCount.value}',
                  onTap: controller.openBookings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BnbOverviewCard(
                  title: appLocalization.dashboardTodayRevenue,
                  value: controller.bnbTodayRevenue.value,
                  onTap: controller.openTodayRevenue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BnbOverviewCard(
                  title: appLocalization.dashboardUnits,
                  value: '${controller.bnbUnitsCount.value}',
                  onTap: controller.openProperties,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildBnbWeeklyReportsSection(BuildContext context) {
    return Obx(() {
      if (!controller.isBnbWorkspace.value) return const SizedBox.shrink();
      // Observe list contents so charts update after quiet reloads.
      final revenue = List<double>.from(controller.weeklyRevenue);
      final occupancy = List<double>.from(controller.weeklyOccupancyPercent);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyBarChartCard(
            context,
            title: appLocalization.dashboardWeeklyRevenue,
            subtitle: appLocalization.dashboardWeekTrend,
            values: revenue,
            maxYCap: null,
            formatTooltip: (v) =>
                Get.find<CurrencyService>().formatBase(v.round()),
          ),
          const SizedBox(height: 16),
          _buildWeeklyBarChartCard(
            context,
            title: appLocalization.dashboardWeeklyOccupancy,
            subtitle: appLocalization.dashboardWeekTrend,
            values: occupancy,
            maxYCap: 100,
            formatTooltip: (v) => '${v.round()}%',
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildWeeklyBarChartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<double> values,
    required double? maxYCap,
    required String Function(double) formatTooltip,
  }) {
    final data = values;
    final maxVal = data.fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxYCap ?? (maxVal <= 0 ? 1.0 : maxVal * 1.12);
    final peakValue = maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        color: _isDark(context)
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        border: Border.all(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark(context) ? 0.28 : 0.06,
            ),
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: _isDark(context)
                      ? Colors.white70
                      : AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatTooltip(rod.toY),
                        TextStyle(
                          color: _isDark(context)
                              ? Colors.white
                              : AppColors.textColorPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 ||
                            i >= DashboardController.weeklyDayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DashboardController.weeklyDayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isDark(context)
                                  ? Colors.white70
                                  : AppColors.textColorSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (_isDark(context)
                            ? Colors.white
                            : AppColors.designInputBorder)
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  DashboardController.weeklyDayLabels.length,
                  (i) {
                    final v = i < data.length ? data[i] : 0.0;
                    final isPeak = peakValue > 0 && v == peakValue;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: v,
                          width: 18,
                          color: isPeak
                              ? AppColors.designAccent
                              : AppColors.designAccent.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              duration: const Duration(milliseconds: 150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, 'Financial Overview', 'Muhtasari wa Fedha'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: _t(context, 'Income', 'Mapato'),
                  icon: Icons.description_outlined,
                  isSelected: controller.isIncomeSelected.value,
                  onTap: controller.selectIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SegmentButton(
                  label: _t(context, 'Expenses', 'Gharama'),
                  icon: Icons.account_balance_wallet_outlined,
                  isSelected: !controller.isIncomeSelected.value,
                  onTap: controller.selectExpenses,
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: _isDark(context)
                ? const Color(0xFF1F1F1F)
                : AppColors.colorWhite,
            border: Border.all(
              color: _isDark(context)
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isDark(context) ? 0.28 : 0.06,
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
                          color: _isDark(context)
                              ? Colors.white70
                              : AppColors.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _legendDot(AppColors.designAccent),
                      const SizedBox(width: 6),
                      Text(
                        _t(context, 'CURRENT', 'SASA'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDark(context)
                              ? Colors.white70
                              : AppColors.textColorSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _legendDot(_chartPreviousColor),
                      const SizedBox(width: 6),
                      Text(
                        _t(context, 'PREVIOUS', 'KABLA'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDark(context)
                              ? Colors.white70
                              : AppColors.textColorSecondary,
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
                            (_isDark(context)
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
                                    color: _isDark(context)
                                        ? Colors.white70
                                        : AppColors.textColorSecondary,
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
                                strokeColor: _isDark(context)
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
              color: _isDark(context)
                  ? const Color(0xFF1F1F1F)
                  : AppColors.colorWhite,
              border: Border.all(
                color: _isDark(context)
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDark(context) ? 0.28 : 0.06,
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
                                  color: _isDark(context)
                                      ? Colors.white70
                                      : AppColors.textColorSecondary,
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
                          (_isDark(context)
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

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? AppColors.designAccent
          : (isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.textColorSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BnbOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _BnbOverviewCard({
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textColorSecondary,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changeColor = isPositive
        ? AppColors.colorSuccessGreen
        : AppColors.paaYanguAlert;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
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
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
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
