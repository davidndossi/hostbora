import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/rent_base_view.dart';
import '../controllers/rent_profit_analysis_dashboard_controller.dart';

class _ProfitUi {
  _ProfitUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF004D40);
  static const Color deepTeal = Color(0xFF00585B);
  static const Color cream = Color(0xFFFDFBF7);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get card => dark ? _t.cardColor : Colors.white;
  Color get cardMuted => dark ? context.tokens.cardBackground : const Color(0xFFF4F4F2);
  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF101828);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

class RentProfitAnalysisDashboardView extends RentBaseView<RentProfitAnalysisDashboardController> {
  RentProfitAnalysisDashboardView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';
  static final NumberFormat _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => _ProfitUi(context).bg;

  @override
  Widget body(BuildContext context) {
    final u = _ProfitUi(context);
    return Obx(() {
      controller.expenses.length;
      if (controller.loadingRealData.value) {
        return const DefaultScreenSkeleton();
      }
      final data = controller.realData.value;
      if (data == null) {
        return Center(
          child: Text(
            _isSw ? 'Hakuna data ya faida bado.' : 'No profit data available yet.',
            style: TextStyle(color: u.muted),
          ),
        );
      }

      final target = controller.targetProfit;
      final actual = controller.actualProfit;
      final deviation = controller.deviationAmount;
      final devPct = controller.deviationPercentVsTarget;
      final targetBars = controller.targetTrendBars();
      final actualBars = controller.actualTrendBars();
      final maxBar = [...targetBars, ...actualBars].fold<double>(0, (a, b) => a > b ? a : b);

      return RefreshIndicator(
        color: _ProfitUi.forest,
        onRefresh: controller.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
          children: [
            Text(
              _isSw ? 'Uchambuzi wa Fedha' : 'Financial Analysis',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 14),
            _moneyCard(
              u,
              label: _isSw ? 'LENGO LA FAIDA' : 'TARGET PROFIT',
              value: target,
              sublabel: _isSw
                  ? 'Kutokana na makadirio ya matumizi/ujazaji ya 25%'
                  : 'Based on 25% occupancy projection',
              icon: Icons.assured_workload_outlined,
              borderColor: Colors.transparent,
            ),
            const SizedBox(height: 10),
            _moneyCard(
              u,
              label: _isSw ? 'FAIDA HALISI' : 'ACTUAL PROFIT',
              value: actual,
              sublabel: _isSw ? 'Mwaka hadi sasa wa mali zote' : 'Net as of all properties',
              icon: Icons.monetization_on_outlined,
              borderColor: _ProfitUi.forest.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            _deviationCard(u, deviation, devPct),
            const SizedBox(height: 16),
            _varianceChartCard(u, targetBars, actualBars, maxBar),
            const SizedBox(height: 16),
            _aiInsightCard(u),
            const SizedBox(height: 16),
            _expenseBreakdownCard(u),
          ],
        ),
      );
    });
  }

  Widget _headerRow(_ProfitUi u) {
    return Row(
      children: [
        const Icon(Icons.menu_rounded, color: Color(0xFF616161), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isSw ? 'Uchambuzi wa Fedha' : 'Financial Analysis',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
        ),
        CircleAvatar(
          radius: 14,
          backgroundColor: u.cardMuted,
          child: Icon(Icons.person_outline, size: 16, color: u.onSurface),
        ),
      ],
    );
  }

  Widget _moneyCard(
    _ProfitUi u, {
    required String label,
    required double value,
    required String sublabel,
    required IconData icon,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: u.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: u.muted,
                ),
              ),
              const Spacer(),
              Icon(icon, color: _ProfitUi.forest, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tsh ${_money.format(value.abs().round())}',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 0.98,
              color: value < 0 ? Colors.red.shade700 : u.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: u.muted),
          ),
        ],
      ),
    );
  }

  Widget _deviationCard(_ProfitUi u, double deviation, double pct) {
    final isNegative = deviation < 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSw ? 'TOFAUTI' : 'DEVIATION',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
              const Spacer(),
              Icon(Icons.warning_amber_rounded, color: Colors.brown.shade700, size: 17),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${isNegative ? '-' : '+'} Tsh ${_money.format(deviation.abs().round())}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${pct.toStringAsFixed(1)}% ${_isSw ? 'tofauti dhidi ya lengo' : 'variance from target'}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.brown.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _varianceChartCard(
    _ProfitUi u,
    List<double> targetBars,
    List<double> actualBars,
    double maxY,
  ) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: u.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Tofauti ya Faida' : 'Profit Variance',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          Text(
            _isSw ? 'Mwenendo wa mwezi kwa mwezi' : 'Monthly Performance',
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_isSw ? 'Linganisho:' : 'Compare:', style: TextStyle(fontSize: 11, color: u.muted)),
              const SizedBox(width: 8),
              _legendDot(u.muted.withValues(alpha: 0.45), _isSw ? 'Lengo' : 'Target', u),
              const SizedBox(width: 12),
              _legendDot(_ProfitUi.forest, _isSw ? 'Halisi' : 'Actual', u),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.18,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            i >= 0 && i < months.length ? months[i] : '',
                            style: TextStyle(fontSize: 9, color: u.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: i < targetBars.length ? targetBars[i] : 0,
                        width: 10,
                        color: u.muted.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: i < actualBars.length ? actualBars[i] : 0,
                        width: 10,
                        color: _ProfitUi.forest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label, _ProfitUi u) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, color: u.muted, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _aiInsightCard(_ProfitUi u) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfitUi.deepTeal,
        borderRadius: BorderRadius.circular(14),
        boxShadow: u.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'AI Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${controller.insightMessage(_isSw)}"',
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSw
                ? 'Pendekezo: Tekeleza ukaguzi wa wiki na mipaka ya idhini kwa kazi za dharura.'
                : 'Recommendation: Implement weekly checks and approval caps for emergency repairs.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.onApplyStrategy,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ProfitUi.deepTeal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isSw ? 'Tumia Mkakati' : 'Apply Strategy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseBreakdownCard(_ProfitUi u) {
    final rows = controller.topExpenseLines;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: u.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSw ? 'Mchanganuo wa Gharama' : 'Expense Breakdown',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
              ),
              Text(
                _isSw
                    ? 'Vipengele ${controller.revivingItemsCount} vinahitaji hatua'
                    : 'Reviving ${controller.revivingItemsCount} line items',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.brown.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _isSw ? 'Hakuna gharama bado.' : 'No expenses yet.',
                style: TextStyle(color: u.muted, fontSize: 12),
              ),
            )
          else
            ...rows.map((line) => _expenseRow(u, line)),
        ],
      ),
    );
  }

  Widget _expenseRow(_ProfitUi u, RentProfitExpenseLine line) {
    final rec = line.record;
    final varPositive = line.variance >= 0;
    final title = rec.notes.trim().isNotEmpty ? rec.notes.trim() : rec.category;
    final subtitle = rec.apartment.trim().isNotEmpty
        ? rec.apartment.trim()
        : (_isSw ? 'Mali ya mijini' : 'Urban lot');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: u.cardMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: _iconColorForCategory(rec.category).withValues(alpha: 0.15),
              child: Icon(
                _iconForCategory(rec.category),
                size: 18,
                color: _iconColorForCategory(rec.category),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: u.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: u.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tsh ${_money.format(rec.amountValue.round())}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
                Text(
                  varPositive
                      ? (_isSw ? 'JUU YA MAKADIRIO' : 'UNPLANNED')
                      : (_isSw ? 'CHINI YA MAKADIRIO' : 'ON BUDGET'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: varPositive ? Colors.red.shade600 : _ProfitUi.forest,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.trim();
    if (c == 'Maintenance') return Icons.build_outlined;
    if (c == 'Utilities') return Icons.bolt_rounded;
    if (c == 'Salary') return Icons.group_outlined;
    if (c == 'Rent') return Icons.apartment_rounded;
    return Icons.receipt_long_outlined;
  }

  Color _iconColorForCategory(String category) {
    final c = category.trim();
    if (c == 'Maintenance') return const Color(0xFFD32F2F);
    if (c == 'Utilities') return const Color(0xFF1976D2);
    if (c == 'Salary') return const Color(0xFF37474F);
    if (c == 'Rent') return const Color(0xFF795548);
    return const Color(0xFF6B7280);
  }
}
