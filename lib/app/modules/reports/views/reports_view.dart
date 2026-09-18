import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends BaseView<ReportsController> {
  ReportsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.reportsHubTitle,
      isCentered: true,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      context.tokens.scaffoldBackground;

  @override
  Widget body(BuildContext context) {
    final tokens = context.tokens;

    return SafeArea(
      child: Column(
        children: [
          _periodBar(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _tabStrip(context),
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
          _exportBar(context, tokens),
        ],
      ),
    );
  }

  Widget _scroll(BuildContext context, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: child,
    );
  }

  Widget _tabStrip(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? tokens.elevatedSurface : const Color(0xFFF1F3F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller.tabController,
        labelColor: Colors.white,
        unselectedLabelColor: tokens.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.colorPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: [
          Tab(text: appLocalization.reportsTabOccupancy),
          Tab(text: appLocalization.reportsTabFinancial),
          Tab(text: appLocalization.reportsTabExpenses),
        ],
      ),
    );
  }

  Widget _periodBar(BuildContext context) {
    return Obx(() {
      final k = controller.periodKind.value;
      final tokens = context.tokens;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FormSurfaceColors.of(context).isDark
                    ? tokens.elevatedSurface
                    : const Color(0xFFF1F3F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _periodSeg(context, ReportsPeriodKind.weekly, k),
                  _periodSeg(context, ReportsPeriodKind.monthly, k),
                  _periodSeg(context, ReportsPeriodKind.yearly, k),
                  _periodSeg(context, ReportsPeriodKind.custom, k),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: tokens.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.rangeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (k == ReportsPeriodKind.custom) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      context,
                      label: appLocalization.reportsPickStartDate,
                      value: controller.customStart.value,
                      onTap: () => controller.pickCustomStart(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: tokens.textMuted,
                    ),
                  ),
                  Expanded(
                    child: _dateTile(
                      context,
                      label: appLocalization.reportsPickEndDate,
                      value: controller.customEnd.value,
                      onTap: () => controller.pickCustomEnd(context),
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

  Widget _periodSeg(
    BuildContext context,
    ReportsPeriodKind value,
    ReportsPeriodKind selected,
  ) {
    final on = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setPeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? AppColors.colorPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            _periodLabel(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? Colors.white : context.tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    final formatted = value == null
        ? '—'
        : MaterialLocalizations.of(context).formatShortDate(value);
    return Material(
      color: FormSurfaceColors.of(context).card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
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
      final avg = controller.averageOccupancy;
      final peak = controller.peakOccupancy;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  context,
                  label: _t(context, 'Average', 'Wastani'),
                  value: '${avg.toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  tint: AppColors.colorPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  context,
                  label: _t(context, 'Peak', 'Kilele'),
                  value: '${peak.toStringAsFixed(0)}%',
                  icon: Icons.insights_rounded,
                  tint: const Color(0xFF5D9CEC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.reportsPropertyFilter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.tokens.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                _propertyDropdown(context),
                const SizedBox(height: 10),
                Text(
                  _t(
                    context,
                    'Occupancy uses overlapping stays versus total BnB units.',
                    'Ukaaji unatumia kukaa vinavyoingiliana dhidi ya vyumba vyote vya BnB.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _chartCard(
            context,
            title: appLocalization.reportsOccupancyChartTitle,
            child: SizedBox(
              height: 220,
              child: controller.bucketLabels.isEmpty
                  ? _emptyState(context)
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: context.tokens.border.withValues(alpha: 0.7),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 ||
                                    i >= controller.bucketLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    controller.bucketLabels[i],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: context.tokens.textMuted,
                                    ),
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
                              interval: 25,
                              getTitlesWidget: (v, m) => Text(
                                '${v.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.tokens.textMuted,
                                ),
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
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots
                                .map(
                                  (s) => LineTooltipItem(
                                    '${s.y.toStringAsFixed(0)}%',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              controller.occupancyPct.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                controller.occupancyPct[i],
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.colorPrimary,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, data, index) =>
                                  FlDotCirclePainter(
                                radius: 3.5,
                                color: AppColors.colorPrimary,
                                strokeWidth: 2,
                                strokeColor:
                                    FormSurfaceColors.of(context).card,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.colorPrimary.withValues(
                                alpha: 0.12,
                              ),
                            ),
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

  Widget _propertyDropdown(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: controller.selectedPropertyRef.value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: tokens.textMuted),
          dropdownColor: FormSurfaceColors.of(context).dropdownBg,
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
    );
  }

  Widget _financialBody(BuildContext context) {
    return Obx(() {
      final labels = controller.bucketLabels;
      final hasExp = controller.hasExpenseSignal;
      final net = controller.totalNet;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  context,
                  label: appLocalization.reportsRevenueSeries,
                  value: controller.formatTzs(controller.totalRevenue),
                  icon: Icons.south_west_rounded,
                  tint: AppColors.colorPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  context,
                  label: appLocalization.reportsExpenseSeries,
                  value: controller.formatTzs(controller.totalExpense),
                  icon: Icons.north_east_rounded,
                  tint: AppColors.colorOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kpiCard(
            context,
            label: appLocalization.reportsNetSeries,
            value: controller.formatTzs(net),
            icon: Icons.account_balance_wallet_outlined,
            tint: net >= 0 ? AppColors.paaYanguSuccess : AppColors.errorColor,
          ),
          if (!hasExp) ...[
            const SizedBox(height: 12),
            _hintBanner(
              context,
              appLocalization.reportsRevenueOnlyHint,
            ),
          ],
          const SizedBox(height: 14),
          _chartCard(
            context,
            title:
                '${appLocalization.reportsRevenueSeries} / ${appLocalization.reportsExpenseSeries}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendDot(AppColors.colorPrimary),
                const SizedBox(width: 4),
                Text(
                  appLocalization.reportsRevenueSeries,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                _legendDot(AppColors.colorOrange),
                const SizedBox(width: 4),
                Text(
                  appLocalization.reportsExpenseSeries,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
            child: labels.isEmpty
                ? SizedBox(height: 220, child: _emptyState(context))
                : Builder(
                    builder: (context) {
                      const barSlotWidth = 36.0;
                      final viewportWidth =
                          MediaQuery.sizeOf(context).width - 64;
                      final chartWidth = math.max(
                        viewportWidth,
                        labels.length * barSlotWidth,
                      );
                      return SizedBox(
                        height: 280,
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
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (v) => FlLine(
                                    color: context.tokens.border
                                        .withValues(alpha: 0.7),
                                    strokeWidth: 1,
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
                                      getTitlesWidget: (v, m) => Text(
                                        _compactMoney(v),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: context.tokens.textMuted,
                                        ),
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
                                          top: Radius.circular(5),
                                        ),
                                      ),
                                      BarChartRodData(
                                        toY: controller.expensePerBucket[i],
                                        width: 10,
                                        color: AppColors.colorOrange,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(5),
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
            const SizedBox(height: 14),
            _sectionCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.reportsNetSeries,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(labels.length, (i) {
                    final rowNet = controller.netAt(i);
                    final positive = rowNet >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: context.tokens.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            controller.formatTzs(rowNet),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: positive
                                  ? AppColors.colorPrimary
                                  : AppColors.errorColor,
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
            fontWeight: FontWeight.w600,
            color: context.tokens.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _expensesBody(BuildContext context) {
    return Obx(() {
      final labels = controller.expenseCategoryLabels.toList();
      final amounts = controller.expenseCategoryAmounts.toList();
      final tokens = context.tokens;
      final maxY = amounts.isEmpty
          ? 100.0
          : amounts.reduce((a, b) => a > b ? a : b) * 1.2;
      final yInterval = _axisInterval(maxY);
      const barSlotWidth = 76.0;
      final viewportWidth = MediaQuery.sizeOf(context).width - 64;
      final chartWidth = math.max(
        viewportWidth,
        labels.length * barSlotWidth,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kpiCard(
            context,
            label: appLocalization.reportsExpenseSeries,
            value: controller.formatTzs(controller.totalExpense),
            icon: Icons.pie_chart_outline_rounded,
            tint: AppColors.paaYanguWarm,
          ),
          const SizedBox(height: 14),
          _chartCard(
            context,
            title: appLocalization.reportsExpenseCategoryChart,
            child: labels.isEmpty
                ? SizedBox(height: 220, child: _emptyState(context))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 280,
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
                                  getDrawingHorizontalLine: (v) => FlLine(
                                    color: tokens.border.withValues(alpha: 0.7),
                                    strokeWidth: 1,
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final i = group.x;
                                      if (i < 0 || i >= labels.length) {
                                        return null;
                                      }
                                      return BarTooltipItem(
                                        '${labels[i]}\n${controller.formatTzs(rod.toY)}',
                                        const TextStyle(
                                          color: Colors.white,
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
                                              color: tokens.textMuted,
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
                                          top: Radius.circular(5),
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
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Divider(color: tokens.border, height: 1),
                        const SizedBox(height: 8),
                        ...List.generate(labels.length, (i) {
                          final total = amounts.fold<double>(0, (a, b) => a + b);
                          final share =
                              total <= 0 ? 0.0 : amounts[i] / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.paaYanguWarm,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(share * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  controller.formatTzs(amounts[i]),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      );
    });
  }

  double _axisInterval(double maxY) {
    if (maxY <= 0) return 25;
    final rough = maxY / 4;
    final magnitude =
        math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
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

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color tint,
  }) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: child,
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = FormSurfaceColors.of(context).isDark;
    return BoxDecoration(
      color: FormSurfaceColors.of(context).card,
      borderRadius: BorderRadius.circular(AppValues.radius_12),
      border: Border.all(
        color: context.tokens.border.withValues(alpha: isDark ? 0.8 : 1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _hintBanner(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).impactBannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: context.tokens.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 36,
            color: context.tokens.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.reportsNoData,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _exportBar(BuildContext context, AppThemeTokens tokens) {
    return Material(
      color: FormSurfaceColors.of(context).card,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Obx(() {
              final busy = controller.exporting.value;
              return Row(
                children: [
                  Expanded(
                    child: _exportBtn(
                      context,
                      label: appLocalization.reportsExportPdf,
                      icon: Icons.picture_as_pdf_outlined,
                      filled: false,
                      onTap: busy ? null : () => controller.exportPdf(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _exportBtn(
                      context,
                      label: appLocalization.reportsExportCsv,
                      icon: Icons.table_chart_outlined,
                      filled: false,
                      onTap: busy ? null : () => controller.exportCsv(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _exportBtn(
                      context,
                      label: appLocalization.reportsExportExcel,
                      icon: Icons.grid_on_outlined,
                      filled: true,
                      busy: busy,
                      onTap: busy ? null : () => controller.exportExcel(context),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _exportBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );

    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.colorPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: child,
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.colorPrimary,
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: AppColors.colorPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: child,
    );
  }
}
