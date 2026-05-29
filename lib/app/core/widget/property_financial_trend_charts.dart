import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_tokens.dart';
import '../utils/property_financial_time_series.dart';
import 'skeleton_presets.dart';

/// Income, costs, and combined line charts vs date for one property.
class PropertyFinancialTrendCharts extends StatelessWidget {
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

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Widget build(BuildContext context) {
    final u = _ChartUi(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SkeletonMetricCard(),
      );
    }

    final data = series;
    if (data == null || data.dateLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'MIKAKATI YA KIFEDHA' : 'FINANCIAL TRENDS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: u.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSw ? 'Mapato na gharama kwa mwezi (miezi 12)' : 'Income & costs by month (last 12 months)',
          style: TextStyle(fontSize: 12, color: u.muted),
        ),
        const SizedBox(height: 14),
        _chartCard(
          u,
          title: _isSw ? 'Mapato dhidi ya tarehe' : 'Income vs date',
          legendLabel: _isSw ? 'Mapato' : 'Income',
          legendColor: incomeColor,
          child: _singleLineChart(
            u,
            values: data.incomeByPeriod,
            labels: data.dateLabels,
            lineColor: incomeColor,
          ),
        ),
        const SizedBox(height: 12),
        _chartCard(
          u,
          title: _isSw ? 'Gharama dhidi ya tarehe' : 'Costs vs date',
          legendLabel: _isSw ? 'Gharama' : 'Costs',
          legendColor: costColor,
          child: _singleLineChart(
            u,
            values: data.costsByPeriod,
            labels: data.dateLabels,
            lineColor: costColor,
          ),
        ),
        const SizedBox(height: 12),
        _chartCard(
          u,
          title: _isSw ? 'Mapato na gharama (pamoja)' : 'Income & costs combined',
          legendLabel: null,
          legendColor: incomeColor,
          child: _combinedLineChart(
            u,
            income: data.incomeByPeriod,
            costs: data.costsByPeriod,
            labels: data.dateLabels,
          ),
          footer: Row(
            children: [
              _legendDot(incomeColor, _isSw ? 'Mapato' : 'Income'),
              const SizedBox(width: 16),
              _legendDot(costColor, _isSw ? 'Gharama' : 'Costs'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartCard(
    _ChartUi u, {
    required String title,
    required String? legendLabel,
    required Color legendColor,
    required Widget child,
    Widget? footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: u.text,
            ),
          ),
          if (legendLabel != null) ...[
            const SizedBox(height: 6),
            _legendDot(legendColor, legendLabel),
          ],
          const SizedBox(height: 12),
          SizedBox(height: 200, child: child),
          if (footer != null) ...[
            const SizedBox(height: 10),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
      return Center(child: Text(_emptyLabel, style: TextStyle(color: u.muted)));
    }
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY <= 0) {
      return Center(child: Text(_emptyLabel, style: TextStyle(color: u.muted)));
    }
    final top = maxY * 1.12;
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

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
              FlLine(color: u.muted.withValues(alpha: 0.2), strokeWidth: 1),
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
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _combinedLineChart(
    _ChartUi u, {
    required List<double> income,
    required List<double> costs,
    required List<String> labels,
  }) {
    if (income.isEmpty) {
      return Center(child: Text(_emptyLabel, style: TextStyle(color: u.muted)));
    }
    final maxY = [...income, ...costs].fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY <= 0) {
      return Center(child: Text(_emptyLabel, style: TextStyle(color: u.muted)));
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
              FlLine(color: u.muted.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _axisTitles(u, labels, top),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: incomeColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: costSpots,
            isCurved: true,
            color: costColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  FlTitlesData _axisTitles(_ChartUi u, List<String> labels, double top) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
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
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: u.muted),
              ),
            );
          },
        ),
      ),
    );
  }

  String get _emptyLabel =>
      _isSw ? 'Hakuna data ya kifedha kwa kipindi hiki' : 'No financial data for this period';

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
}
