import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_financial_comparison_controller.dart';

class _FinUi {
  _FinUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF133834);
  static const Color terracotta = Color(0xFF8B3A2B);
  static const Color cream = Color(0xFFF9F8F3);
  static const Color cardTint = Color(0xFFF2F1EB);

  Color get canvas => dark ? _t.scaffoldBackgroundColor : cream;

  Color get card => dark ? _t.cardColor : Colors.white;

  Color get metricCardBg => dark ? context.tokens.cardBackground : cardTint;

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get muted =>
      dark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);

  Color get forestOnBg => dark ? const Color(0xFF5EC9C3) : forest;

  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.07),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
}

class RentFinancialComparisonView extends RentBaseView<RentFinancialComparisonController> {
  RentFinancialComparisonView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => _FinUi(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
      appBarTitleText: _isSw ? 'Ulinganisho wa Kifedha' : 'Financial Comparison'
  );

  @override
  Widget body(BuildContext context) {
    final u = _FinUi(context);
    return Obx(() {
      if (controller.loadingDash.value || controller.loadingRealData.value) {
        return const DefaultScreenSkeleton();
      }
      return RefreshIndicator(
        color: _FinUi.forest,
        onRefresh: () async {
          await controller.loadRealDataSnapshot();
          await controller.loadDashboard();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              _isSw ? 'UCHUMI WA MALI' : 'PORTFOLIO ECONOMICS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 14),
            _metricRow(context),
            const SizedBox(height: 22),
            _incomeCostCard(context),
            const SizedBox(height: 20),
            _performersCard(context),
            const SizedBox(height: 24),
            _tenantSectionHeader(context),
            const SizedBox(height: 14),
            _tenantCarousel(context),
          ],
        ),
      );
    });
  }

  Widget _metricRow(BuildContext context) {
    final u = _FinUi(context);
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _metricTile(
              context,
              label: _isSw ? 'FAIDA JUMLA YA MWAKA' : 'TOTAL ANNUAL PROFIT',
              value: controller.formatTshFull(controller.annualProfit.value),
              valueColor: u.forestOnBg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              context,
              label: _isSw ? 'KIWANGO CHA FAIDA HALISI' : 'NET MARGIN',
              value: controller.formatMargin(controller.netMarginPct.value),
              valueColor: u.dark ? const Color(0xFFFFAB91) : _FinUi.terracotta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final u = _FinUi(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.metricCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: context.tokens.elevatedSurface) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomeCostCard(BuildContext context) {
    final u = _FinUi(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: context.tokens.elevatedSurface) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Mapato dhidi ya Gharama' : 'Income vs. Cost Analysis',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.forestOnBg,
            ),
          ),
          const SizedBox(height: 14),
          _granularityToggle(context),
          const SizedBox(height: 18),
          SizedBox(height: 220, child: Obx(() => _lineChart(context))),
          const SizedBox(height: 16),
          Obx(() => _chartLegend(context)),
        ],
      ),
    );
  }

  Widget _granularityToggle(BuildContext context) {
    final u = _FinUi(context);
    return Obx(
      () {
        final g = controller.granularity.value;
        Widget pill(String en, String sw, FinancialChartGranularity val) {
          final sel = g == val;
          return Expanded(
            child: Material(
              color: sel ? _FinUi.forest : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => controller.setGranularity(val),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _isSw ? sw : en,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sel ? Colors.white : u.muted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: u.dark ? context.tokens.elevatedSurface : _FinUi.cardTint,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              pill('Monthly', 'Mwezi', FinancialChartGranularity.monthly),
              pill('Quarterly', 'Robo', FinancialChartGranularity.quarterly),
              pill('Yearly', 'Mwaka', FinancialChartGranularity.yearly),
            ],
          ),
        );
      },
    );
  }

  Widget _lineChart(BuildContext context) {
    final u = _FinUi(context);
    final labels = controller.chartXLabels;
    final inc = controller.chartIncomeY;
    final cost = controller.chartCostY;
    if (labels.isEmpty || inc.isEmpty) {
      return Center(child: Text(_isSw ? 'Hakuna data' : 'No data', style: TextStyle(color: u.muted)));
    }

    final n = inc.length;
    final maxY = [
      ...inc,
      ...cost,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY <= 0 ? 100.0 : maxY * 1.15;

    final incomeSpots = List.generate(n, (i) => FlSpot(i.toDouble(), inc[i]));
    final costSpots = List.generate(n, (i) => FlSpot(i.toDouble(), cost[i]));

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
          getDrawingHorizontalLine: (_) => FlLine(
            color: u.muted.withValues(alpha: 0.2),
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
              reservedSize: 36,
              interval: top / 4,
              getTitlesWidget: (v, m) => Text(
                v >= 1e6 ? '${(v / 1e6).toStringAsFixed(1)}M' : '${(v / 1e3).round()}k',
                style: TextStyle(fontSize: 9, color: u.muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, m) {
                final i = v.round();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
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
            spots: incomeSpots,
            isCurved: true,
            color: _FinUi.forest,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _FinUi.forest.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: costSpots,
            isCurved: true,
            color: _FinUi.terracotta,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _FinUi.terracotta.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _chartLegend(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _legendLine(
                context,
                _FinUi.forest,
                _isSw ? 'Jumla ya Mapato' : 'Total Income',
                controller.formatTshShort(controller.legendIncome.value),
              ),
            ),
            Expanded(
              child: _legendLine(
                context,
                _FinUi.terracotta,
                _isSw ? 'Jumla ya Gharama' : 'Total Costs',
                controller.formatTshShort(controller.legendCost.value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _legendLine(
          context,
          _FinUi.forest,
          _isSw ? 'Faida Halisi' : 'Net Profit',
          controller.formatTshShort(controller.legendNet.value),
        ),
      ],
    );
  }

  Widget _legendLine(BuildContext context, Color dot, String label, String value) {
    final u = _FinUi(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: u.muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: u.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _performersCard(BuildContext context) {
    final u = _FinUi(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.metricCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: context.tokens.elevatedSurface) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Wenye Utendaji Bora' : 'Highest Performers',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.forestOnBg,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.performers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _isSw ? 'Ongeza mali na miamala ili kuona utendaji.' : 'Add properties and transactions to see performance.',
                  style: TextStyle(color: u.muted, fontSize: 13),
                ),
              );
            }
            return Column(
              children: controller.performers
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _performerRow(context, p),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 8),
          Obx(
            () => controller.performerInsight.value.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: u.dark ? context.tokens.scaffoldBackground : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: u.muted.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      controller.performerInsight.value,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: u.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _performerRow(BuildContext context, PropertyPerformerVm p) {
    final u = _FinUi(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.barFraction.clamp(0.02, 1.0),
                  minHeight: 10,
                  backgroundColor: u.dark ? const Color(0xFF48484A) : const Color(0xFFE0DED6),
                  color: _FinUi.forest,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              controller.formatTshShort(p.profit),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: u.forestOnBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tenantSectionHeader(BuildContext context) {
    final u = _FinUi(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Faida ya Wapangaji' : 'Tenant Profitability',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.forestOnBg,
            ),
          ),
        ),
        TextButton(
          onPressed: controller.openTenantDirectory,
          child: Text(
            _isSw ? 'Angalia daftari kamili →' : 'View Detailed Ledger →',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: u.forestOnBg,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tenantCarousel(BuildContext context) {
    final u = _FinUi(context);
    return Obx(() {
      if (controller.tenantProfits.isEmpty) {
        return Text(
          _isSw ? 'Hakuna wapangaji waliorekodiwa.' : 'No tenants on file yet.',
          style: TextStyle(color: u.muted),
        );
      }
      return SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.tenantProfits.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) {
            final t = controller.tenantProfits[i];
            return _tenantCard(context, t);
          },
        ),
      );
    });
  }

  Widget _tenantCard(BuildContext context, TenantProfitVm t) {
    final u = _FinUi(context);
    final rest = (100 - t.profitPct).clamp(1, 100);
    return SizedBox(
      width: 272,
      height: 210,
      child: Material(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: u.shadow,
            border: u.dark ? Border.all(color: context.tokens.elevatedSurface) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: u.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.addressLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: u.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 18,
                            sections: [
                              PieChartSectionData(
                                value: t.profitPct.toDouble(),
                                color: _FinUi.forest,
                                radius: 14,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: rest.toDouble(),
                                color: u.dark ? const Color(0xFF48484A) : const Color(0xFFE8E6E1),
                                radius: 14,
                                showTitle: false,
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 150),
                        ),
                        Text(
                          '${t.profitPct}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: u.forestOnBg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSw ? 'Mapato ya mwezi' : 'Monthly Income',
                    style: TextStyle(fontSize: 11, color: u.muted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    controller.formatTshShort(t.monthlyIncome),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSw ? 'Gharama & matengenezo' : 'Exp. & Maintenance',
                    style: TextStyle(fontSize: 11, color: u.muted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    controller.formatTshShort(t.expenseMaint),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: u.dark ? const Color(0xFFFFAB91) : _FinUi.terracotta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => controller.openTenantLedger(t),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isSw ? 'Angalia' : 'View',
                  style: TextStyle(fontWeight: FontWeight.w800, color: u.forestOnBg, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
