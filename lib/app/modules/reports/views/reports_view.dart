import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_decorations.dart';
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
    return SafeArea(
      child: Column(
        children: [
        _periodBar(context),
        Material(
          color: AppColors.colorWhite,
          child: TabBar(
            controller: controller.tabController,
            labelColor: AppColors.colorPrimary,
            unselectedLabelColor: AppColors.colorDark,
            indicatorColor: AppColors.colorPrimary,
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
    return FilterChip(
      label: Text(_periodLabel(value)),
      selected: selectedStyle,
      onSelected: (_) => controller.setPeriod(value),
      selectedColor: AppColors.colorPrimaryLight,
      checkmarkColor: AppColors.colorPrimary,
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
                fillColor: AppColors.colorWhite,
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
                  color: AppColors.colorDark,
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
                      color: AppColors.colorDark,
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
            SizedBox(
              height: 240,
              child: labels.isEmpty
                  ? Center(child: Text(appLocalization.reportsNoData))
                  : BarChart(
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
                              reservedSize: 32,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  labels[i],
                                  style: const TextStyle(fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              BarChartRodData(
                                toY: controller.expensePerBucket[i],
                                width: 10,
                                color: AppColors.colorOrange,
                                borderRadius: const BorderRadius.vertical(
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

  Widget _expensesBody(BuildContext context) {
    return Obx(() {
      final labels = controller.expenseCategoryLabels;
      final amounts = controller.expenseCategoryAmounts;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalization.reportsExpenseCategoryChart,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _chartCard(
            context,
            SizedBox(
              height: 260,
              child: labels.isEmpty
                  ? Center(child: Text(appLocalization.reportsNoData))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: amounts.isEmpty ? 100 : amounts.reduce((a, b) => a > b ? a : b) * 1.15,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    labels[i],
                                    style: const TextStyle(fontSize: 9),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
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
                                toY: amounts[i],
                                width: 14,
                                color: AppColors.paaYanguWarm,
                                borderRadius: const BorderRadius.vertical(
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
        ],
      );
    });
  }

  Widget _chartCard(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: child,
    );
  }

  Widget _exportBar(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppColors.colorWhite,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.exportPdf,
                  child: Text(appLocalization.reportsExportPdf),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.exportCsv,
                  child: Text(appLocalization.reportsExportCsv),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                  ),
                  onPressed: controller.exportExcel,
                  child: Text(appLocalization.reportsExportExcel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
