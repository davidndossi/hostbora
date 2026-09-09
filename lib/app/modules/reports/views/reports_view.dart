import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends BaseView<ReportsController> {
  ReportsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.reportsHubTitle,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark teal on dark surface is hard to see — use a lighter selected accent.
    final selectedTabColor =
        isDark ? const Color(0xFF5ECFBF) : AppColors.colorPrimary;
    final unselectedTabColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      child: Column(
        children: [
        _periodBar(context),
        Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface,
          child: TabBar(
            controller: controller.tabController,
            labelColor: selectedTabColor,
            unselectedLabelColor: unselectedTabColor,
            indicatorColor: selectedTabColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            dividerColor: isDark ? const Color(0xFF3A3A3C) : null,
            tabs: [
              Tab(text: appLocalization.reportsTabOccupancy),
              Tab(text: appLocalization.reportsTabFinancial),
              Tab(text: appLocalization.reportsTabExpenses),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => controller.isLoading.value
                ? const DefaultScreenSkeleton()
                : TabBarView(
                    controller: controller.tabController,
                    children: [
                      _scroll(context, _occupancyBody(context)),
                      _scroll(context, _financialBody(context)),
                      _scroll(context, _expensesBody(context)),
                    ],
                  ),
          ),
        ),
        _exportBar(context),
        ],
      ),
    );
  }

  Widget _scroll(BuildContext context, Widget child) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: child,
      ),
    );
  }

  Widget _periodBar(BuildContext context) {
    return Obx(() {
      final k = controller.periodKind.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, ReportsPeriodKind.weekly, k),
                _chip(context, ReportsPeriodKind.monthly, k),
                _chip(context, ReportsPeriodKind.yearly, k),
                _chip(context, ReportsPeriodKind.custom, k),
              ],
            ),
            if (k == ReportsPeriodKind.custom) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.pickCustomStart(context),
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        '${appLocalization.reportsPickStartDate}: '
                        '${controller.customStart.value != null ? MaterialLocalizations.of(context).formatShortDate(controller.customStart.value!) : '—'}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.pickCustomEnd(context),
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        '${appLocalization.reportsPickEndDate}: '
                        '${controller.customEnd.value != null ? MaterialLocalizations.of(context).formatShortDate(controller.customEnd.value!) : '—'}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _chip(BuildContext context, ReportsPeriodKind value, ReportsPeriodKind selected) {
    final selectedStyle = value == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg =
        isDark ? AppColors.colorPrimary : AppColors.colorPrimaryLight;
    final selectedFg = isDark ? Colors.white : AppColors.colorPrimary;
    final unselectedFg = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : Theme.of(context).colorScheme.onSurface;

    return FilterChip(
      label: Text(
        _periodLabel(value),
        style: TextStyle(
          color: selectedStyle ? selectedFg : unselectedFg,
          fontWeight: selectedStyle ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selectedStyle,
      onSelected: (_) => controller.setPeriod(value),
      selectedColor: selectedBg,
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : null,
      checkmarkColor: selectedFg,
      side: BorderSide(
        color: selectedStyle
            ? (isDark ? AppColors.colorPrimary : AppColors.colorPrimary)
            : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD0D0D0)),
        width: selectedStyle ? 1.5 : 1,
      ),
      showCheckmark: true,
    );
  }

  String _periodLabel(ReportsPeriodKind k) {
    switch (k) {
      case ReportsPeriodKind.weekly:
        return appLocalization.reportsPeriodWeekly;
      case ReportsPeriodKind.monthly:
        return appLocalization.reportsPeriodMonthly;
      case ReportsPeriodKind.yearly:
        return appLocalization.reportsPeriodYearly;
      case ReportsPeriodKind.custom:
        return appLocalization.reportsPeriodCustom;
    }
  }

  Widget _occupancyBody(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.reportsPropertyFilter,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Obx(
            () => InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: controller.selectedPropertyRef.value,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(appLocalization.reportsPropertyAll),
                    ),
                    ...controller.bnbProperties.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p.propertyRef,
                        child: Text(
                          p.propertyName.trim().isEmpty
                              ? p.propertyRef
                              : p.propertyName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: controller.setPropertyFilter,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.reportsOccupancyFormulaNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            appLocalization.reportsOccupancyChartTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _chartCard(
            context,
            SizedBox(
              height: 220,
              child: controller.bucketLabels.isEmpty
                  ? Center(child: Text(appLocalization.reportsNoData))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 || i >= controller.bucketLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    controller.bucketLabels[i],
                                    style: const TextStyle(fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, m) => Text(
                                '${v.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              controller.occupancyPct.length,
                              (i) => FlSpot(i.toDouble(), controller.occupancyPct[i]),
                            ),
                            isCurved: true,
                            color: AppColors.colorPrimary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _financialBody(BuildContext context) {
    return Obx(() {
      final labels = controller.bucketLabels;
      final hasExp = controller.hasExpenseSignal;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasExp)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                appLocalization.reportsRevenueOnlyHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          Text(
            '${appLocalization.reportsRevenueSeries} / ${appLocalization.reportsExpenseSeries}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _chartCard(
            context,
            labels.isEmpty
                ? SizedBox(
                    height: 240,
                    child: Center(child: Text(appLocalization.reportsNoData)),
                  )
                : Builder(
                    builder: (context) {
                      const barSlotWidth = 36.0;
                      final viewportWidth =
                          MediaQuery.sizeOf(context).width - 48;
                      final chartWidth = math.max(
                        viewportWidth,
                        labels.length * barSlotWidth,
                      );
                      return SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _maxY([
                                  ...controller.revenuePerBucket,
                                  ...controller.expensePerBucket,
                                ]),
                                gridData: const FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 78,
                                      getTitlesWidget: (v, meta) {
                                        final i = v.toInt();
                                        if (i < 0 || i >= labels.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return _verticalBottomTitle(
                                          context,
                                          labels[i],
                                          meta,
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 44,
                                      getTitlesWidget: (v, m) => Text(
                                        _compactMoney(v),
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(labels.length, (i) {
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: controller.revenuePerBucket[i],
                                        width: 10,
                                        color: AppColors.colorPrimary,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                      BarChartRodData(
                                        toY: controller.expensePerBucket[i],
                                        width: 10,
                                        color: AppColors.colorOrange,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                    barsSpace: 4,
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (hasExp) ...[
            const SizedBox(height: 12),
            Text(
              appLocalization.reportsNetSeries,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            ...List.generate(labels.length, (i) {
              final net = controller.netAt(i);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(labels[i], style: const TextStyle(fontSize: 13))),
                    Text(
                      controller.formatTzs(net),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: net >= 0 ? AppColors.colorPrimary : AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  String _compactMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.round().toString();
  }

  double _maxY(List<double> values) {
    final m = values.fold<double>(0, (a, b) => a > b ? a : b);
    return m <= 0 ? 100 : m * 1.15;
  }

  /// Bottom axis labels drawn vertically so dense periods stay readable.
  Widget _verticalBottomTitle(
    BuildContext context,
    String label,
    TitleMeta meta,
  ) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      angle: -math.pi / 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 72),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            height: 1.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _expensesBody(BuildContext context) {
    return Obx(() {
      final labels = controller.expenseCategoryLabels.toList();
      final amounts = controller.expenseCategoryAmounts.toList();
      final theme = Theme.of(context);
      final maxY = amounts.isEmpty
          ? 100.0
          : amounts.reduce((a, b) => a > b ? a : b) * 1.2;
      final yInterval = _axisInterval(maxY);
      // Give each category enough horizontal room so labels never collide.
      const barSlotWidth = 76.0;
      final viewportWidth = MediaQuery.sizeOf(context).width - 48;
      final chartWidth = math.max(
        viewportWidth,
        labels.length * barSlotWidth,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.reportsExpenseCategoryChart,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _chartCard(
            context,
            labels.isEmpty
                ? SizedBox(
                    height: 220,
                    child: Center(child: Text(appLocalization.reportsNoData)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,
                                groupsSpace: 18,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: yInterval,
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final i = group.x;
                                      if (i < 0 || i >= labels.length) {
                                        return null;
                                      }
                                      return BarTooltipItem(
                                        '${labels[i]}\n${controller.formatTzs(rod.toY)}',
                                        TextStyle(
                                          color: theme.colorScheme.onInverseSurface,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 78,
                                      getTitlesWidget: (v, meta) {
                                        final i = v.toInt();
                                        if (i < 0 || i >= labels.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return _verticalBottomTitle(
                                          context,
                                          labels[i],
                                          meta,
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 44,
                                      interval: yInterval,
                                      getTitlesWidget: (v, meta) {
                                        // Skip near-duplicate edge ticks that crowd the axis.
                                        if (v < 0 || v > maxY + 0.01) {
                                          return const SizedBox.shrink();
                                        }
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 4,
                                          child: Text(
                                            _compactMoney(v),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(labels.length, (i) {
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: amounts[i],
                                        width: 18,
                                        color: AppColors.paaYanguWarm,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(labels.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.paaYanguWarm,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  labels[i],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                controller.formatTzs(amounts[i]),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      );
    });
  }

  /// Evenly spaced Y-axis ticks so money labels do not stack on top of each other.
  double _axisInterval(double maxY) {
    if (maxY <= 0) return 25;
    final rough = maxY / 4;
    final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final residual = rough / magnitude;
    final nice = residual <= 1
        ? 1.0
        : residual <= 2
            ? 2.0
            : residual <= 5
                ? 5.0
                : 10.0;
    return nice * magnitude;
  }

  Widget _chartCard(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _exportBar(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Obx(() {
            final busy = controller.exporting.value;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => controller.exportPdf(context),
                    child: Text(appLocalization.reportsExportPdf),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => controller.exportCsv(context),
                    child: Text(appLocalization.reportsExportCsv),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                    ),
                    onPressed:
                        busy ? null : () => controller.exportExcel(context),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(appLocalization.reportsExportExcel),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
