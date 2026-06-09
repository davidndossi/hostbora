import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../core/widget/skeleton_presets.dart';
import '../controllers/rent_utility_usage_graph_controller.dart';

class _GraphUi {
  _GraphUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF0A5C5C);
  static const Color mint = Color(0xFFCFE6DF);
  static const Color cream = Color(0xFFFBF9F4);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
}

class RentUtilityUsageGraphView extends RentBaseView<RentUtilityUsageGraphController> {
  RentUtilityUsageGraphView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => _GraphUi(context).bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final loc = appLocalization;
    final title = controller.isLuku
        ? loc.rentUtilityUsageGraphScreenTitleLuku
        : loc.rentUtilityUsageGraphScreenTitleWater;
    return CustomAppBar(appBarTitleText: title);
  }

  @override
  Widget body(BuildContext context) {
    final u = _GraphUi(context);
    final loc = appLocalization;
    return Obx(() {
      if (controller.loading.value) {
        return const Center(
          child: DefaultScreenSkeleton(),
        );
      }
      return RefreshIndicator(
        color: _GraphUi.forest,
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Text(
              loc.rentUtilityUsageGraphChartCaption,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 16),
            if (!controller.hasAnyData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    loc.rentUtilityUsageGraphEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: u.muted,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 29,
                    minY: 0,
                    maxY: controller.maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: controller.maxY > 4 ? controller.maxY / 4 : 1.0,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: u.muted.withValues(alpha: 0.25),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, meta) {
                            final label = (v - v.round()).abs() < 0.001
                                ? v.round().toString()
                                : v.toStringAsFixed(1);
                            return Text(
                              label,
                              style: TextStyle(fontSize: 10, color: u.muted),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 6,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i != 0 && i != 6 && i != 12 && i != 18 && i != 24 && i != 29) {
                              return const SizedBox.shrink();
                            }
                            final today = DateTime.now();
                            final day = DateTime(today.year, today.month, today.day)
                                .subtract(Duration(days: 29 - i));
                            final label = '${day.month}/${day.day}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: u.muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          controller.dailyTotals.length,
                          (i) => FlSpot(i.toDouble(), controller.dailyTotals[i]),
                        ),
                        isCurved: true,
                        color: _GraphUi.forest,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            final y = spot.y;
                            if (y <= 0) {
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                              );
                            }
                            return FlDotCirclePainter(
                              radius: 3.5,
                              color: _GraphUi.forest,
                              strokeWidth: 2,
                              strokeColor: u.dark ? context.tokens.scaffoldBackground : Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _GraphUi.forest.withValues(alpha: u.dark ? 0.12 : 0.08),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 200),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: u.dark ? context.tokens.cardBackground : _GraphUi.mint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isLuku ? Icons.bolt_rounded : Icons.water_drop_rounded,
                    color: _GraphUi.forest,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.isLuku
                          ? loc.rentUtilityUsageGraphFootnoteLuku
                          : loc.rentUtilityUsageGraphFootnoteWater,
                      style: TextStyle(fontSize: 12, color: u.onSurface, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
