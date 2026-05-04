import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../routes/app_pages.dart';
import '../controllers/rent_property_roi_analysis_controller.dart';

class _RoiUi {
  _RoiUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF004D40);
  static const Color teal = Color(0xFF00796B);
  static const Color cream = Color(0xFFF9F8F4);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get card => dark ? _t.cardColor : Colors.white;
  Color get cardMuted => dark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F2);
  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
  Color get incomeTint => dark ? const Color(0xFF1B3D3A) : const Color(0xFFE0F2F1);

  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Financial overview — principal, income yield, investment vs income chart, breakdown, portfolio.
class RentPropertyRoiAnalysisView extends BaseView<RentPropertyRoiAnalysisController> {
  RentPropertyRoiAnalysisView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  static final NumberFormat _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => _RoiUi(context).bg;

  @override
  Widget body(BuildContext context) {
    final u = _RoiUi(context);
    return Obx(() {
      if (controller.loadingRealData.value) {
        return Center(child: CircularProgressIndicator(color: u.dark ? _RoiUi.teal : _RoiUi.forest));
      }
      final d = controller.realData.value;
      if (d == null) {
        return Center(
          child: Text(
            _isSw ? 'Hakuna data ya ROI bado.' : 'No ROI data available yet.',
            style: TextStyle(color: u.muted),
          ),
        );
      }

      final incomeTotal = d.incomeTotal;
      final principal = controller.principalInvestment;
      final yieldPct = controller.yieldToDatePercent(incomeTotal);
      final qInv = controller.quarterlyInvestmentSeries(principal);
      final qInc = controller.quarterlyIncomeSeries(incomeTotal);
      final maxChartY = [
        ...qInv,
        ...qInc,
      ].fold<double>(0, (a, b) => a > b ? a : b) * 1.15;

      return Stack(
        children: [
          RefreshIndicator(
            color: _RoiUi.forest,
            onRefresh: controller.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // _headerRow(u),
                const SizedBox(height: 20),
                Text(
                  _isSw ? 'MUHTASARI WA KIFEDHA' : 'PRINCIPAL INVESTMENT',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    color: u.muted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  principal > 0 ? 'Tsh ${_money.format(principal.round())}' : '—',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: u.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: u.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        principal > 0
                            ? (_isSw
                                ? 'Mtaji wa kwanza uliotumika kwenye mali ${controller.portfolio.length} za mijini.'
                                : 'Initial capital deployed across ${controller.portfolio.length} urban properties.')
                            : (_isSw
                                ? 'Ongeza makadirio ya mali ili kuona mtaji wa msingi na ROI halisi.'
                                : 'Add property estimates to calculate principal investment and ROI.'),
                        style: TextStyle(fontSize: 12, height: 1.35, color: u.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _incomeCard(u, incomeTotal, yieldPct),
                const SizedBox(height: 16),
                _chartCard(u, qInv, qInc, maxChartY),
                const SizedBox(height: 14),
                _acquisitionCard(u),
                const SizedBox(height: 10),
                _renovationCard(u, d.expenseTotal),
                const SizedBox(height: 10),
                _maintenanceCard(u),
                const SizedBox(height: 22),
                _portfolioHeader(u),
                const SizedBox(height: 12),
                ...controller.portfolio.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _propertyCard(u, p),
                    )),
                if (controller.portfolio.isEmpty)
                  Text(
                    _isSw ? 'Hakuna mali zilizorekodiwa.' : 'No properties on file yet.',
                    style: TextStyle(color: u.muted),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton(
              backgroundColor: _RoiUi.forest,
              foregroundColor: Colors.white,
              onPressed: () async {
                final ref = controller.selectedPropertyRef.value.trim();
                if (ref.isEmpty) {
                  controller.showSuccessMessage(
                    _isSw ? 'Chagua mali kutoka orodha ya mali.' : 'Select a property from your listings first.',
                  );
                  return;
                }
                final result = await Get.toNamed(
                  Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
                  parameters: {
                    'propertyRef': ref,
                    'propertyLabel': controller.selectedPropertyLabel.value,
                  },
                );
                if (result == true) await controller.loadAll();
              },
              child: const Icon(Icons.note_add_outlined),
            ),
          ),
        ],
      );
    });
  }

  // Widget _headerRow(_RoiUi u) {
  //   return Row(
  //     children: [
  //       Container(
  //         width: 28,
  //         height: 28,
  //         decoration: BoxDecoration(
  //           color: _RoiUi.forest,
  //           borderRadius: BorderRadius.circular(6),
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: Text(
  //           _isSw ? 'Muhtasari wa Fedha' : 'Financial Overview',
  //           style: TextStyle(
  //             fontFamily: 'serif',
  //             fontSize: 20,
  //             fontWeight: FontWeight.w700,
  //             color: u.onSurface,
  //           ),
  //         ),
  //       ),
  //       Icon(Icons.tune_rounded, color: u.muted, size: 22),
  //       const SizedBox(width: 8),
  //       CircleAvatar(
  //         radius: 16,
  //         backgroundColor: u.cardMuted,
  //         child: Icon(Icons.person_outline_rounded, size: 18, color: u.onSurface),
  //       ),
  //     ],
  //   );
  // }

  Widget _incomeCard(_RoiUi u, double incomeTotal, double yieldPct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.incomeTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RoiUi.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'JUMLA YA MAPATO YALIYOTENGenezwa' : 'TOTAL INCOME GENERATED',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: _RoiUi.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tsh ${_money.format(incomeTotal.round())}',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _RoiUi.teal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: u.dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              Text(
                '+ ${yieldPct.toStringAsFixed(1)}% ${_isSw ? 'Marejesho hadi sasa' : 'Yield to Date'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: u.dark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard(_RoiUi u, List<double> qInv, List<double> qInc, double maxY) {
    const labels = ['JAN - MAR', 'APR - JUN', 'JUL - SEP', 'OCT - DEC'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: const Color(0xFF48484A)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Uwekezaji dhidi ya Mapato' : 'Investment vs Income',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          Text(
            _isSw
                ? 'Ulinganisho wa kila mwezi kwa mwaka wa fedha 2024.'
                : 'Monthly comparative performance for the fiscal year 2024.',
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(_RoiUi.forest, _isSw ? 'UWEKEZAJI' : 'INVESTMENT'),
              const SizedBox(width: 16),
              _legendDot(_RoiUi.teal, _isSw ? 'MAPATO' : 'INCOME'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY <= 0 ? 1 : maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: u.muted.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            i >= 0 && i < labels.length ? labels[i] : '',
                            style: TextStyle(fontSize: 8, color: u.muted),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(4, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: qInv.length > i ? qInv[i] : 0,
                        width: 10,
                        color: _RoiUi.forest,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: qInc.length > i ? qInc[i] : 0,
                        width: 10,
                        color: _RoiUi.teal,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
      ],
    );
  }

  Widget _acquisitionCard(_RoiUi u) {
    final v = controller.acquisitionCost;
    return _greyCard(
      u,
      icon: Icons.apartment_rounded,
      title: _isSw ? 'Gharama ya Ununuzi' : 'Acquisition Cost',
      subtitle: _isSw ? 'Bei ya Ununuzi wa Mali' : 'Asset Purchase Price',
      amount: v > 0 ? 'Tsh ${_money.format(v.round())}' : '—',
      footer: Row(
        children: [
          Text(
            _isSw ? 'USHURU WA STAMPU UMEOJUMISHWA' : 'STAMP DUTY INCL',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: u.muted),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _RoiUi.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _isSw ? 'Imelipwa' : 'Paid',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _RoiUi.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renovationCard(_RoiUi u, double expenseTotal) {
    final committed = controller.renovationCommitted;
    final utilized = controller.renovationUtilized(expenseTotal);
    final frac = committed > 0 ? (utilized / committed).clamp(0.0, 1.0) : 0.0;
    return _greyCard(
      u,
      icon: Icons.stairs_rounded,
      title: _isSw ? 'Ukarabati wa Makadirio' : 'Estimated Renovation',
      subtitle: _isSw ? 'Miradi ya uboreshaji' : 'Capital improvement projects',
      amount: committed > 0 ? 'Tsh ${_money.format(committed.round())}' : '—',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSw ? 'JUMLA ILIYOJITOLEA' : 'SUM COMMITTED',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: u.muted),
              ),
              const Spacer(),
              Text(
                'Tsh ${_money.format(utilized.round())} ${_isSw ? 'IMETUMIKA' : 'UTILIZED'}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: u.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: u.muted.withValues(alpha: 0.15),
              color: const Color(0xFF8B3A2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceCard(_RoiUi u) {
    return _greyCard(
      u,
      icon: Icons.build_rounded,
      title: _isSw ? 'Makadirio ya Matengenezo' : 'Maintenance Forecast',
      subtitle: _isSw ? 'Akiba ya kudumu' : 'Ongoing reserve',
      amount: '',
      footer: Text(
        _isSw
            ? 'Mfumo unaweka kando 2.15% ya mapato ya kila mwezi kwa matengenezo ya dharura na kuzuia kushuka kwa thamani ya mali.'
            : 'The system allocates 2.15% of monthly revenue to a maintenance reserve for emergency repairs and asset value preservation.',
        style: TextStyle(fontSize: 12, height: 1.45, color: u.muted),
      ),
    );
  }

  Widget _greyCard(
    _RoiUi u, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Widget footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: u.card,
                child: Icon(icon, size: 18, color: u.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: u.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: u.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (amount.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: u.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 10),
          footer,
        ],
      ),
    );
  }

  Widget _portfolioHeader(_RoiUi u) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Kwingineko cha Mali' : 'Property Portfolio',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Get.toNamed(Routes.MY_PROPERTIES),
          style: FilledButton.styleFrom(
            backgroundColor: _RoiUi.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            _isSw ? 'Ona Mali Zote' : 'View All Assets',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  static const _badges = ['HIGH YIELD', 'COMMERCIAL', 'GROWTH ASSET'];

  Widget _propertyCard(_RoiUi u, PropertyRecord p) {
    final loc = p.propertyLocation.trim();
    final suite = p.apartmentSuite.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : (loc.isNotEmpty ? loc : 'Property');
    final badge = _badges[p.id % _badges.length];
    final roi = controller.roiLabelForProperty(p);

    return Container(
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: const Color(0xFF48484A)) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'images/luxury_room_view.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: u.cardMuted),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 2),
                Text(
                  loc.isNotEmpty ? loc : '—',
                  style: TextStyle(fontSize: 12, color: u.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: u.muted),
                          ),
                          Text(
                            roi ?? '—',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: u.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSw ? 'HALI' : 'STATUS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: u.muted),
                          ),
                          Text(
                            _isSw ? 'Hai' : 'Active',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: u.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
