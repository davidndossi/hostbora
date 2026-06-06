import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_tokens.dart';
import '../utils/property_financial_time_series.dart';
import 'skeleton_presets.dart';

enum _ChartMode { income, costs, both }

/// Single switchable line chart — income / costs / both — for one property.
class PropertyFinancialTrendCharts extends StatefulWidget {
  const PropertyFinancialTrendCharts({
    super.key,
    required this.series,
    this.loading = false,
    this.incomeColor = const Color(0xFF0A5C5C),
    this.costColor = const Color(0xFFB85C38),
  });

  final PropertyFinancialTimeSeries? series;
  final bool loading;
  final Color incomeColor;
  final Color costColor;

  @override
  State<PropertyFinancialTrendCharts> createState() =>
      _PropertyFinancialTrendChartsState();
}

class _PropertyFinancialTrendChartsState
    extends State<PropertyFinancialTrendCharts> {
  _ChartMode _mode = _ChartMode.both;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _modeLabel(_ChartMode m) {
    switch (m) {
      case _ChartMode.income:
        return _isSw ? 'Mapato tu' : 'Income only';
      case _ChartMode.costs:
        return _isSw ? 'Gharama tu' : 'Costs only';
      case _ChartMode.both:
        return _isSw ? 'Mapato & Gharama' : 'Income & Costs';
    }
  }

  String get _chartTitle {
    switch (_mode) {
      case _ChartMode.income:
        return _isSw ? 'Mapato dhidi ya tarehe' : 'Income vs date';
      case _ChartMode.costs:
        return _isSw ? 'Gharama dhidi ya tarehe' : 'Costs vs date';
      case _ChartMode.both:
        return _isSw ? 'Mapato & Gharama (pamoja)' : 'Income & Costs combined';
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _ChartUi(context);

    if (widget.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SkeletonMetricCard(),
      );
    }

    final data = widget.series;
    if (data == null || data.dateLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section meta
        Text(
          _isSw ? 'MIKAKATI YA KIFEDHA' : 'FINANCIAL TRENDS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: u.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _isSw
              ? 'Mapato na gharama kwa mwezi (miezi 12)'
              : 'Income & costs by month (last 12 months)',
          style: TextStyle(fontSize: 12, color: u.muted),
        ),
        const SizedBox(height: 14),

        // Single chart card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: u.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: u.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row with dropdown ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _chartTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: u.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: u.soft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: u.line),
                    ),
                    child: DropdownButton<_ChartMode>(
                      value: _mode,
                      isDense: true,
                      underline: const SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: u.muted,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: u.text,
                      ),
                      dropdownColor: u.card,
                      borderRadius: BorderRadius.circular(12),
                      items: _ChartMode.values
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(_modeLabel(m)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _mode = v);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Legend ──────────────────────────────────────────────
              Row(
                children: [
                  if (_mode != _ChartMode.costs)
                    _legendDot(
                      u,
                      widget.incomeColor,
                      _isSw ? 'Mapato' : 'Income',
                    ),
                  if (_mode == _ChartMode.both) const SizedBox(width: 16),
                  if (_mode != _ChartMode.income)
                    _legendDot(
                      u,
                      widget.costColor,
                      _isSw ? 'Gharama' : 'Costs',
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Chart ───────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: SizedBox(
                  key: ValueKey(_mode),
                  height: 210,
                  child: _buildChart(u, data),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(_ChartUi u, PropertyFinancialTimeSeries data) {
    switch (_mode) {
      case _ChartMode.income:
        return _singleLineChart(
          u,
          values: data.incomeByPeriod,
          labels: data.dateLabels,
          lineColor: widget.incomeColor,
        );
      case _ChartMode.costs:
        return _singleLineChart(
          u,
          values: data.costsByPeriod,
          labels: data.dateLabels,
          lineColor: widget.costColor,
        );
      case _ChartMode.both:
        return _combinedLineChart(
          u,
          income: data.incomeByPeriod,
          costs: data.costsByPeriod,
          labels: data.dateLabels,
        );
    }
  }

  Widget _legendDot(_ChartUi u, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: u.muted,
          ),
        ),
      ],
    );
  }

  Widget _singleLineChart(
    _ChartUi u, {
    required List<double> values,
    required List<String> labels,
    required Color lineColor,
  }) {
    if (values.isEmpty) {
      return Center(
        child: Text(_emptyLabel, style: TextStyle(color: u.muted)),
      );
    }
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY <= 0) {
      return Center(
        child: Text(_emptyLabel, style: TextStyle(color: u.muted)),
      );
    }
    final top = maxY * 1.12;
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: u.muted.withValues(alpha: 0.18), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _axisTitles(u, labels, top),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: lineColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.18),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
    );
  }

  Widget _combinedLineChart(
    _ChartUi u, {
    required List<double> income,
    required List<double> costs,
    required List<String> labels,
  }) {
    if (income.isEmpty) {
      return Center(
        child: Text(_emptyLabel, style: TextStyle(color: u.muted)),
      );
    }
    final maxY = [...income, ...costs].fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY <= 0) {
      return Center(
        child: Text(_emptyLabel, style: TextStyle(color: u.muted)),
      );
    }
    final top = maxY * 1.12;
    final n = income.length;
    final incomeSpots = List.generate(n, (i) => FlSpot(i.toDouble(), income[i]));
    final costSpots = List.generate(n, (i) => FlSpot(i.toDouble(), costs[i]));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: 0,
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: u.muted.withValues(alpha: 0.18), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _axisTitles(u, labels, top),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: widget.incomeColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.incomeColor.withValues(alpha: 0.12),
                  widget.incomeColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: costSpots,
            isCurved: true,
            color: widget.costColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.costColor.withValues(alpha: 0.10),
                  widget.costColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
    );
  }

  FlTitlesData _axisTitles(_ChartUi u, List<String> labels, double top) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: top / 4,
          getTitlesWidget: (v, _) => Text(
            _formatAxis(v),
            style: TextStyle(fontSize: 9, color: u.muted),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (v, _) {
            final i = v.round();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: u.muted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String get _emptyLabel => _isSw
      ? 'Hakuna data ya kifedha kwa kipindi hiki'
      : 'No financial data for this period';

  static String _formatAxis(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).round()}k';
    return v.round().toString();
  }
}

class _ChartUi {
  _ChartUi(this.context);

  final BuildContext context;
  AppThemeTokens get _tokens => context.tokens;
  Color get card => _tokens.cardBackground;
  Color get line => _tokens.border;
  Color get text => _tokens.textPrimary;
  Color get muted => _tokens.textMuted;
  Color get soft => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3A3A3C)
      : const Color(0xFFF4F1EA);
}
