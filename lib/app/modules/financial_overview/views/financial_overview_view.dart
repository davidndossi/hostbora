import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/financial_overview_controller.dart';

class FinancialOverviewView extends BaseView<FinancialOverviewController> {
  FinancialOverviewView({super.key});

  static const _chartPreviousColor = Color(0xFFE07A5F);

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.financialOverview,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const DefaultScreenSkeleton();
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          _circleIconButton(
            context: context,
            onPressed: controller.goBack,
            icon: Icons.chevron_left,
          ),
          const Spacer(),
          TextButton(
            onPressed: controller.recordPayment,
            child: Text(
              _t(context, en: 'Record Payment', sw: 'Rekodi Malipo'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.colorPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _circleIconButton(
            context: context,
            onPressed: controller.openCalendar,
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.1),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'Financial Overview', sw: 'Muhtasari wa Fedha'),
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
                  label: _t(context, en: 'Income', sw: 'Mapato'),
                  icon: Icons.description_outlined,
                  isSelected: controller.isIncomeSelected.value,
                  onTap: controller.selectIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SegmentButton(
                  label: _t(context, en: 'Expenses', sw: 'Matumizi'),
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
      return _performanceTrendsChart(
        context,
        currentSpots,
        previousSpots,
      );
    });
  }

  Widget _performanceTrendsChart(
    BuildContext context,
    List<FlSpot> currentSpots,
    List<FlSpot> previousSpots,
  ) {
    const minY = 0.0;
    const maxY = 6.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).isDark
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      context,
                      en: 'Performance Trends',
                      sw: 'Mwelekeo wa Utendaji',
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
                      en: 'Current vs. Previous Period',
                      sw: 'Kipindi cha sasa dhidi ya kilichopita',
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
                    _t(context, en: 'CURRENT', sw: 'SASA'),
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
                    _t(context, en: 'PREVIOUS', sw: 'KILICHOPITA'),
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
          SizedBox(
            height: 180,
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
                            i <
                                FinancialOverviewController
                                    .trendLabels
                                    .length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              FinancialOverviewController.trendLabels[i],
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
            ? _t(context, en: 'Total Revenue', sw: 'Jumla ya Mapato')
            : _t(context, en: 'Total Expenses', sw: 'Jumla ya Gharama'),
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
                      en: 'Avg. Daily Rate',
                      sw: 'Wastani wa Bei ya Siku',
                    )
                  : _t(
                      context,
                      en: 'Avg. Daily Expense',
                      sw: 'Wastani wa Gharama kwa Siku',
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
                  ? _t(context, en: 'Net Profit', sw: 'Faida Halisi')
                  : _t(context, en: 'Month Change', sw: 'Mabadiliko ya Mwezi'),
              value: isIncome
                  ? controller.netProfit.value
                  : controller.totalExpensesChange.value,
              change: isIncome
                  ? controller.netProfitChange.value
                  : _t(context, en: 'vs. prev month', sw: 'dhidi ya mwezi uliopita'),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        );
      });

      final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
      final maxY = maxVal <= 0
          ? 6.0
          : (maxVal * 1.08).clamp(6.0, double.infinity);

      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, en: 'Monthly Growth', sw: 'Ukuaji wa Kila Mwezi'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FormSurfaceColors.of(context).isDark
                ? const Color(0xFF1F1F1F)
                : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
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
    final c = FormSurfaceColors.of(context);
    return Material(
      color: isSelected
          ? AppColors.designAccent
          : (c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite),
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
                    color: c.isDark
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
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
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
