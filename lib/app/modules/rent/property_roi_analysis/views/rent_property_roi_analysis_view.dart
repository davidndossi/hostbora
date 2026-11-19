import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/skeleton_presets.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_analysis_controller.dart';

class _RoiUi {
  _RoiUi(this.context);

  final BuildContext context;

  bool get dark => Theme.of(context).brightness == Brightness.dark;

  static const Color forest = Color(0xFF004D40);
  static const Color teal = Color(0xFF0E6666);
  static const Color brown = Color(0xFF5D4037);

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF101828);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
  Color get card => dark ? Theme.of(context).cardColor : Colors.white;
  Color get border => dark ? Colors.white12 : const Color(0xFFE5E7EB);
  Color get softTeal =>
      dark ? const Color(0xFF1B3D3A) : const Color(0xFFE0F2F1);
  Color get softMuted =>
      dark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F5F7);
}

/// Selected-property ROI: principal, income, costs, break-even, estimate edit.
class RentPropertyRoiAnalysisView
    extends RentBaseView<RentPropertyRoiAnalysisController> {
  RentPropertyRoiAnalysisView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _fmt(num value) => Get.find<CurrencyService>().formatBase(value.round());

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
        _isSw ? 'Uchambuzi wa ROI' : 'Property ROI',
    isCentered: false
      );

  @override
  Widget body(BuildContext context) {
    final u = _RoiUi(context);
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }

      final income = controller.incomeForProperty;
      final principal = controller.principalInvestment;
      final yieldPct = controller.yieldToDatePercent;
      final hasEstimate = controller.hasEstimate;

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _RoiUi.forest,
              onRefresh: controller.loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Expanded(
                    child: Text(
                      _isSw ? 'Mapato ya Uwekezaji' : 'Return On Investment',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.displayPropertyTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: u.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSw
                        ? 'Mtaji, mapato na umiliki wa mali hii pekee'
                        : 'Principal, income and break-even for this property',
                    style: TextStyle(fontSize: 13, color: u.muted),
                  ),
                  const SizedBox(height: 18),
                  if (!hasEstimate) ...[
                    _emptyEstimateCard(u),
                  ] else ...[
                    _kpiRow(u, principal, controller.estimatedRoiPercent),
                    const SizedBox(height: 12),
                    _incomeCard(u, income, yieldPct),
                    const SizedBox(height: 12),
                    _costBreakdown(u),
                    if (controller.showCostVsIncomeChart) ...[
                      const SizedBox(height: 12),
                      _ratioChart(u, principal, income),
                      const SizedBox(height: 12),
                      _comparisonBars(u, principal, income),
                    ],
                    const SizedBox(height: 12),
                    _breakEvenCard(u),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.openEstimateForm,
                  icon: Icon(
                    hasEstimate
                        ? Icons.edit_outlined
                        : Icons.note_add_outlined,
                  ),
                  label: Text(
                    hasEstimate
                        ? (_isSw
                            ? 'Hariri makadirio'
                            : 'Edit cost estimate')
                        : (_isSw
                            ? 'Ongeza makadirio ya gharama'
                            : 'Add cost estimate'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _RoiUi.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _emptyEstimateCard(_RoiUi u) {
    return rentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pie_chart_outline, color: _RoiUi.teal, size: 28),
          const SizedBox(height: 12),
          Text(
            _isSw ? 'Hakuna makadirio bado' : 'No cost estimate yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSw
                ? 'Ongeza bei ya ununuzi, ukarabati na mapato yanayotarajiwa ili kuona ROI na umiliki.'
                : 'Add purchase price, renovation and expected income to see ROI and break-even for this property.',
            style: TextStyle(fontSize: 13, height: 1.4, color: u.muted),
          ),
          if (controller.incomeForProperty > 0) ...[
            const SizedBox(height: 14),
            Divider(color: u.border),
            const SizedBox(height: 10),
            Text(
              _isSw ? 'Mapato yaliyorekodiwa' : 'Income recorded so far',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: u.muted),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(controller.incomeForProperty),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: u.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpiRow(_RoiUi u, double principal, double estRoi) {
    return Row(
      children: [
        Expanded(
          child: _kpiTile(
            u,
            label: _isSw ? 'Mtaji' : 'Principal',
            value: principal > 0 ? _fmt(principal) : '—',
            hint: _isSw ? 'Ununuzi + ukarabati' : 'Purchase + renovation',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiTile(
            u,
            label: _isSw ? 'ROI (makadirio)' : 'Est. ROI',
            value: '${estRoi.toStringAsFixed(1)}%',
            hint: _isSw ? 'Faida halisi / mwaka' : 'Annual net / principal',
            accent: true,
          ),
        ),
      ],
    );
  }

  Widget _kpiTile(
    _RoiUi u, {
    required String label,
    required String value,
    required String hint,
    bool accent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? u.softTeal : u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ? _RoiUi.teal.withValues(alpha: 0.25) : u.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: accent ? _RoiUi.teal : u.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: accent ? _RoiUi.teal : u.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(fontSize: 11, color: u.muted)),
        ],
      ),
    );
  }

  Widget _incomeCard(_RoiUi u, double income, double yieldPct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.softTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _RoiUi.teal.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (_isSw ? 'Mapato yaliyotengenezwa' : 'Income generated')
                .toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
              color: _RoiUi.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(income),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _RoiUi.teal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.trending_up_outlined,
                size: 16,
                color: u.dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 4),
              Text(
                '${yieldPct.toStringAsFixed(1)}% ${_isSw ? 'marejesho hadi sasa' : 'yield to date'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: u.dark
                      ? const Color(0xFF81C784)
                      : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costBreakdown(_RoiUi u) {
    return rentCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Mgawanyo wa gharama' : 'Cost breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _costRow(
            u,
            Icons.home_work_outlined,
            _isSw ? 'Ununuzi' : 'Acquisition',
            controller.acquisitionCost > 0
                ? _fmt(controller.acquisitionCost)
                : '—',
          ),
          _costRow(
            u,
            Icons.construction_outlined,
            _isSw ? 'Ukarabati' : 'Renovation',
            controller.renovationCommitted > 0
                ? _fmt(controller.renovationCommitted)
                : '—',
          ),
          _costRow(
            u,
            Icons.build_outlined,
            _isSw ? 'Matengenezo (halisi)' : 'Maintenance (actual)',
            controller.maintenanceActual > 0
                ? _fmt(controller.maintenanceActual)
                : '—',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _costRow(
    _RoiUi u,
    IconData icon,
    String label,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 6 : 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: u.softMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: u.muted),
          ),
          const SizedBox(width: 10),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratioChart(_RoiUi u, double principal, double income) {
    final maintenance = controller.maintenanceForChart;
    final total = principal + maintenance + income;
    if (total <= 0) return const SizedBox.shrink();

    double pct(double v) => (v / total * 100).clamp(0.1, 100);

    final sections = <PieChartSectionData>[
      if (principal > 0)
        PieChartSectionData(
          value: principal,
          color: _RoiUi.forest,
          title: '${pct(principal).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      if (maintenance > 0)
        PieChartSectionData(
          value: maintenance,
          color: _RoiUi.brown,
          title: '${pct(maintenance).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      if (income > 0)
        PieChartSectionData(
          value: income,
          color: _RoiUi.teal,
          title: '${pct(income).toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
    ];

    return rentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Mtaji dhidi ya mapato' : 'Cost vs income',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: sections,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (principal > 0)
                        _legend(u, _RoiUi.forest, _isSw ? 'Mtaji' : 'Principal',
                            _fmt(principal)),
                      if (maintenance > 0) ...[
                        const SizedBox(height: 8),
                        _legend(
                          u,
                          _RoiUi.brown,
                          _isSw ? 'Matengenezo' : 'Maintenance',
                          _fmt(maintenance),
                        ),
                      ],
                      if (income > 0) ...[
                        const SizedBox(height: 8),
                        _legend(
                          u,
                          _RoiUi.teal,
                          _isSw ? 'Mapato' : 'Income',
                          _fmt(income),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(_RoiUi u, Color color, String label, String amount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: u.muted)),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonBars(_RoiUi u, double principal, double income) {
    final maintenance = controller.maintenanceActual;
    final maxY = [principal, income, maintenance]
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (maxY <= 0) return const SizedBox.shrink();

    final items = <(String, double, Color)>[
      (_isSw ? 'Mtaji' : 'Principal', principal, _RoiUi.forest),
      (_isSw ? 'Mapato' : 'Income', income, _RoiUi.teal),
      (_isSw ? 'Matengenezo' : 'Maintenance', maintenance, _RoiUi.brown),
    ];

    return rentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Muhtasari wa kulinganisha' : 'At a glance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((item) {
            final frac = (item.$2 / maxY).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: u.muted,
                          ),
                        ),
                      ),
                      Text(
                        item.$2 > 0 ? _fmt(item.$2) : '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: u.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: u.softMuted,
                      color: item.$3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _breakEvenCard(_RoiUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.softMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _RoiUi.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_bottom_outlined, color: _RoiUi.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_isSw ? 'Makadirio ya umiliki' : 'Break-even estimate')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: u.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.breakEvenLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: u.onSurface,
                  ),
                ),
                if (controller.monthlyNetForBreakEven > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    _isSw
                        ? 'Mtiririko wa kila mwezi: ${_fmt(controller.monthlyNetForBreakEven)}'
                        : 'Net cash flow used: ${_fmt(controller.monthlyNetForBreakEven)} / month',
                    style: TextStyle(fontSize: 11, color: u.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
