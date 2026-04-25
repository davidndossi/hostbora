import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../../../data/local/db/rent_expense_local_data_source.dart';
import '../controllers/rent_maintenance_cost_analysis_controller.dart';

class _McaUi {
  _McaUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF004D40);
  static const Color teal = Color(0xFF00796B);
  static const Color cream = Color(0xFFFDFBF7);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get card => dark ? _t.cardColor : Colors.white;
  Color get cardMuted => dark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F2);
  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Maintenance & expense breakdown — totals, categorization table, reserve, trend chart.
class RentMaintenanceCostAnalysisView extends BaseView<RentMaintenanceCostAnalysisController> {
  RentMaintenanceCostAnalysisView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  static final NumberFormat _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => _McaUi(context).bg;

  @override
  Widget body(BuildContext context) {
    final u = _McaUi(context);
    return Obx(() {
      controller.expenses.length;
      if (controller.loadingRealData.value) {
        return Center(
          child: CircularProgressIndicator(
            color: u.dark ? _McaUi.teal : _McaUi.forest,
          ),
        );
      }
      final d = controller.realData.value;
      if (d == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _isSw ? 'Hakuna data bado.' : 'No financial data available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: u.muted),
            ),
          ),
        );
      }

      final months = controller.trendHorizonMonths.value;
      final actualSeries = controller.maintenanceTrendActual(months);
      final estSeries = controller.maintenanceTrendEstimated(months);
      final labels = controller.trendMonthLabels(months);
      final maxY = [
        ...actualSeries,
        ...estSeries,
      ].fold<double>(0, (a, b) => a > b ? a : b);
      final chartMaxY = maxY <= 0 ? 100.0 : maxY * 1.2;

      return RefreshIndicator(
        color: _McaUi.forest,
        onRefresh: controller.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // _headerRow(u),
            const SizedBox(height: 20),
            Text(
              _isSw
                  ? 'Uchambuzi wa Gharama za Matengenezo'
                  : 'Maintenance & Expense Breakdown',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w800,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isSw
                  ? 'Simamia matumizi ya matengenezo na ulinganishe na makadirio ili kuimarisha mipango ya kifedha ya mali yako.'
                  : 'Strategic fiscal management for your portfolio—compare actual spend to estimates and spot variances early.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: u.muted,
              ),
            ),
            const SizedBox(height: 20),
            _totalExpensesCard(u),
            const SizedBox(height: 16),
            _categorizationCard(u),
            const SizedBox(height: 16),
            _reserveCard(u),
            const SizedBox(height: 16),
            _lastRepairCard(u),
            const SizedBox(height: 16),
            _trendCard(u, actualSeries, estSeries, labels, chartMaxY),
          ],
        ),
      );
    });
  }

  Widget _headerRow(_McaUi u) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _McaUi.forest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isSw ? 'Muhtasari wa Fedha' : 'Financial Overview',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
        ),
        Icon(Icons.query_stats_rounded, color: u.muted, size: 24),
      ],
    );
  }

  Widget _totalExpensesCard(_McaUi u) {
    final total = controller.displayQuarterTotal;
    final over = controller.overBudgetPercent;
    final periodEn = controller.quarterHasData
        ? 'Q${controller.currentQuarter} ${DateTime.now().year}'
        : 'ALL PERIODS';
    final periodSw = controller.quarterHasData
        ? 'Robo ${controller.currentQuarter} ${DateTime.now().year}'
        : 'VIPINDI VYOTE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: u.cardMuted,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw
                ? 'JUMLA YA GHARAMA HALISI ($periodSw)'
                : 'TOTAL ACTUAL EXPENSES ($periodEn)',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tsh ${_money.format(total.round())}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _McaUi.teal,
            ),
          ),
          const SizedBox(height: 8),
          if (total > 0)
            Row(
              children: [
                Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '${over >= 0 ? '+' : ''}${over.toStringAsFixed(1)}% ${_isSw ? 'juu ya bajeti' : 'over budget'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            )
          else
            Text(
              _isSw ? 'Ongeza gharama kuona mlinganisho na bajeti.' : 'Add expenses to compare against budget.',
              style: TextStyle(fontSize: 12, color: u.muted),
            ),
        ],
      ),
    );
  }

  Widget _categorizationCard(_McaUi u) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: const Color(0xFF48484A)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _isSw ? 'Aina za Gharama' : 'Expense Categorization',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.showSuccessMessage(
                  _isSw
                      ? 'PDF itapatikana hivi karibuni.'
                      : 'PDF export coming soon.',
                ),
                icon: Icon(Icons.picture_as_pdf_outlined, size: 18, color: _McaUi.teal),
                label: Text(
                  _isSw ? 'PAKUA PDF' : 'DOWNLOAD PDF',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _McaUi.teal,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tableHeader(u),
          const Divider(height: 20),
          ...controller.categoryLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _categoryRow(u, line),
              )),
        ],
      ),
    );
  }

  Widget _tableHeader(_McaUi u) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            _isSw ? 'AINA' : 'CATEGORY',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _isSw ? 'MAKADIRIO' : 'ESTIMATED',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _isSw ? 'HALISI' : 'ACTUAL',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _isSw ? 'TOFAUTI' : 'VARIANCE',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(_McaUi u, RentExpenseCategoryLine line) {
    final v = line.variancePercent;
    final over = v > 0.5;
    final varColor = over ? Colors.red.shade400 : _McaUi.teal;
    final label = _isSw ? line.labelSw : line.labelEn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _categoryIcon(line.id),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: u.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Tsh ${_money.format(line.estimated.round())}',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Tsh ${_money.format(line.actual.round())}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _McaUi.teal,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: varColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryIcon(String id) {
    switch (id) {
      case 'maintenance':
        return CircleAvatar(
          radius: 14,
          backgroundColor: _McaUi.teal.withValues(alpha: 0.15),
          child: const Icon(Icons.build_circle_outlined, size: 16, color: _McaUi.teal),
        );
      case 'taxes':
        return CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF795548).withValues(alpha: 0.12),
          child: const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF795548)),
        );
      case 'utilities':
        return CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.12),
          child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF1976D2)),
        );
      case 'staff':
        return CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF263238).withValues(alpha: 0.08),
          child: const Icon(Icons.work_outline_rounded, size: 16, color: Color(0xFF263238)),
        );
      default:
        return CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.category_outlined, size: 16, color: Colors.grey.shade700),
        );
    }
  }

  Widget _reserveCard(_McaUi u) {
    final liq = controller.maintenanceReserveLiquidity;
    final goal = controller.maintenanceReserveGoal;
    final pct = controller.reserveProgress * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _McaUi.forest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: u.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _isSw ? 'AKIBA YA MATENGENEZO' : 'MAINTENANCE RESERVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            liq > 0 ? 'Tsh ${_money.format(liq.round())}' : '—',
            style: const TextStyle(
              fontFamily: 'serif',
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSw ? 'Liquidity ya sasa' : 'Total Current Liquidity',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_isSw ? 'LENGO' : 'GOAL'}: Tsh ${_money.format(goal.round())}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.reserveProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB2DFDB)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isSw
                ? 'Kutenga 10% ya mapato ya kila mwezi kwa uboreshaji wa mali na matengenezo makubwa baadaye.'
                : 'Allocating 10% of monthly revenue to future property enhancements and capital repairs.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lastRepairCard(_McaUi u) {
    final e = controller.lastMaintenanceExpense;
    final title = _repairTitle(e);
    final dateStr = _repairDate(e);
    final amt = e == null ? 0.0 : e.amountValue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.cardMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'UKANDALA MKUU WA MWISHO' : 'LAST MAJOR REPAIR',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.cottage_outlined, color: _McaUi.forest, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: u.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e == null
                          ? (_isSw ? 'Hakuna tarehe' : 'No date')
                          : '${_isSw ? 'Imekamilika' : 'Completed'} $dateStr • Tsh ${_money.format(amt.round())}',
                      style: TextStyle(fontSize: 13, color: u.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _repairTitle(RentExpenseRecord? e) {
    if (e == null) {
      return _isSw ? 'Hakuna rekodi ya matengenezo' : 'No maintenance expense yet';
    }
    final n = e.notes.trim();
    if (n.isNotEmpty) {
      return n.length > 42 ? '${n.substring(0, 39)}…' : n;
    }
    final ap = e.apartment.trim();
    if (ap.isNotEmpty) return ap;
    return _isSw ? 'Matengenezo' : 'Maintenance';
  }

  String _repairDate(RentExpenseRecord? e) {
    if (e == null) return '';
    final d = DateTime.tryParse(e.datePaidIso);
    if (d == null) return '';
    return DateFormat('MMM d, yyyy').format(d);
  }

  Widget _trendCard(
    _McaUi u,
    List<double> actual,
    List<double> estimated,
    List<String> labels,
    double maxY,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: const Color(0xFF48484A)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Mwenendo wa Matengenezo' : 'Maintenance Trend',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          Text(
            _isSw
                ? 'Uchambuzi wa gharama za matengenezo ya haraka dhidi ya matengenezo ya kujikinga.'
                : 'Historical analysis of reactive vs proactive upkeep costs.',
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
          const SizedBox(height: 14),
          _horizonToggle(u),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: u.muted.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text(
                        v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                        style: TextStyle(fontSize: 9, color: u.muted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i].toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: u.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < estimated.length; i++)
                        FlSpot(i.toDouble(), estimated[i]),
                    ],
                    isCurved: true,
                    color: u.muted.withValues(alpha: 0.6),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < actual.length; i++) FlSpot(i.toDouble(), actual[i]),
                    ],
                    isCurved: true,
                    color: _McaUi.forest,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 3.5,
                        color: _McaUi.forest,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendSquare(
                u,
                u.muted.withValues(alpha: 0.5),
                _isSw ? 'MAKADIRIO YA BAJETI' : 'ESTIMATED BUDGET',
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _McaUi.forest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSw ? 'MATUMIZI HALISI' : 'ACTUAL EXPENDITURE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: u.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendSquare(_McaUi u, Color c, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: u.muted,
          ),
        ),
      ],
    );
  }

  Widget _horizonToggle(_McaUi u) {
    final m = controller.trendHorizonMonths.value;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: u.cardMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _seg(
              u,
              labelEn: '6 MONTHS',
              labelSw: 'MIEZI 6',
              selected: m == 6,
              onTap: () => controller.trendHorizonMonths.value = 6,
            ),
          ),
          Expanded(
            child: _seg(
              u,
              labelEn: '1 YEAR',
              labelSw: 'MWAKA 1',
              selected: m == 12,
              onTap: () => controller.trendHorizonMonths.value = 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(
    _McaUi u, {
    required String labelEn,
    required String labelSw,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            _isSw ? labelSw : labelEn,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: selected ? _McaUi.forest : u.muted,
            ),
          ),
        ),
      ),
    );
  }
}
