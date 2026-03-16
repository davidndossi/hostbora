import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends BaseView<DashboardController> {
  DashboardView({super.key});

  static const _chartPreviousColor = Color(0xFFE07A5F);

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.dashboard,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
          icon: const Icon(Icons.notifications_none_outlined),
        ),
        IconButton(
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          icon: const Icon(Icons.more_vert_outlined)
        )
      ]
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(
              () {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(
      () {
        final isIncome = controller.isIncomeSelected.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: isIncome ? controller.recordPayment : controller.addExpense,
                child: Text(
                  isIncome ? 'Record Payment' : 'Add Expense',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _circleIconButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Material(
      color: AppColors.colorWhite,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 24, color: AppColors.textColorPrimary),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: 'Income',
                  icon: Icons.description_outlined,
                  isSelected: controller.isIncomeSelected.value,
                  onTap: controller.selectIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SegmentButton(
                  label: 'Expenses',
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
    return Obx(
      () {
        final isIncome = controller.isIncomeSelected.value;
        final current = isIncome ? controller.currentTrendValues : controller.currentExpenseTrendValues;
        final previous = isIncome ? controller.previousTrendValues : controller.previousExpenseTrendValues;
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
        return _performanceTrendsChart(currentSpots, previousSpots);
      },
    );
  }

  Widget _performanceTrendsChart(List<FlSpot> currentSpots, List<FlSpot> previousSpots) {
    final minY = 0.0;
    final maxY = 6.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 700,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
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
                        'Performance Trends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Current vs. Previous Period',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _legendDot(AppColors.designAccent),
                      const SizedBox(width: 6),
                      Text(
                        'CURRENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _legendDot(_chartPreviousColor),
                      const SizedBox(width: 6),
                      Text(
                        'PREVIOUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorSecondary,
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
                        color: AppColors.designInputBorder.withOpacity(0.5),
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
                            if (i >= 0 && i < DashboardController.trendLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  DashboardController.trendLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textColorSecondary,
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
                                strokeColor: AppColors.colorWhite,
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTotalRevenueCard(BuildContext context) {
    return Obx(
      () {
        final isIncome = controller.isIncomeSelected.value;
        return _MetricCard(
          label: isIncome ? 'Total Revenue' : 'Total Expenses',
          value: isIncome ? controller.totalRevenue.value : controller.totalExpenses.value,
          change: isIncome ? controller.totalRevenueChange.value : controller.totalExpensesChange.value,
          isPositive: isIncome ? controller.totalRevenueUp.value : controller.totalExpensesUp.value,
          fullWidth: true,
        );
      },
    );
  }

  Widget _buildMetricRow(BuildContext context) {
    return Obx(
      () {
        final isIncome = controller.isIncomeSelected.value;
        return Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: isIncome ? 'Avg. Daily Rate' : 'Avg. Daily Expense',
                value: isIncome ? controller.avgDailyRate.value : controller.avgDailyExpense.value,
                change: isIncome ? controller.avgDailyRateChange.value : controller.avgDailyExpenseChange.value,
                isPositive: isIncome ? controller.avgDailyRateUp.value : controller.avgDailyExpenseUp.value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: isIncome ? 'Net Profit' : 'Month Change',
                value: isIncome ? controller.netProfit.value : controller.totalExpensesChange.value,
                change: isIncome ? controller.netProfitChange.value : 'vs. prev month',
                isPositive: isIncome ? controller.netProfitUp.value : controller.totalExpensesUp.value,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyGrowthSection(BuildContext context) {
    return Obx(
      () {
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
                color: AppColors.designAccent.withOpacity(0.6),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            showingTooltipIndicators: [],
          );
        });
        final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
        final maxY = (maxVal > 0 ? maxVal : 6.0).clamp(6.0, 10.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Growth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textColorSecondary,
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
                        color: AppColors.designInputBorder.withOpacity(0.5),
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
      },
    );
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
    return Material(
      color: isSelected
          ? AppColors.designAccent
          : AppColors.colorWhite,
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
                : Border.all(color: AppColors.designInputBorder),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textColorPrimary,
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
    final changeColor = isPositive
        ? AppColors.colorSuccessGreen
        : AppColors.paaYanguAlert;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
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
