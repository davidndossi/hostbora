import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widget/skeleton_presets.dart';
import '../../rent_theme.dart';
import '../controllers/rent_monthly_pl_summary_controller.dart';

class _PlUi {
  _PlUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  Color get scaffold =>
      dark ? _t.scaffoldBackgroundColor : const Color(0xFFF8F7F4);

  Color get card => _t.cardColor;

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);

  Color get muted =>
      dark ? const Color(0xFFAEAEB2) : RentTheme.muted;

  static const Color forest = Color(0xFF004D40);
  static const Color lightTeal = Color(0xFF80CBC4);
  static const Color expenseRed = Color(0xFF8B3A3A);

  Color get forestOnBg => dark ? lightTeal : forest;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class RentMonthlyPlSummaryView extends RentBaseView<RentMonthlyPlSummaryController> {
  RentMonthlyPlSummaryView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => _PlUi(context).scaffold;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loadingMonth.value) {
        return const DefaultScreenSkeleton();
      }

      return RefreshIndicator(
        color: _PlUi.forest,
        onRefresh: () async {
          await controller.loadRealDataSnapshot();
          await controller.loadMonthData();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _headerSection(context),
            const SizedBox(height: 16),
            _netProfitCard(context),
            const SizedBox(height: 20),
            _revenueCard(context),
            const SizedBox(height: 16),
            _expenseCard(context),
            const SizedBox(height: 16),
            _efficiencyCard(context),
            // const SizedBox(height: 16),
            // _aiInsightsCard(context),
            const SizedBox(height: 24),
            _actionButtons(context),
          ],
        ),
      );
    });
  }

  Widget _headerSection(BuildContext context) {
    final u = _PlUi(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          _isSw ? 'TAARIFA YA KIFEDHA' : 'FINANCIAL STATEMENT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: u.muted,
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => InkWell(
            onTap: () => controller.pickMonth(),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  controller.monthTitle(isSw: _isSw),
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded, color: u.muted, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _netProfitCard(BuildContext context) {
    final u = _PlUi(context);
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: _PlUi.forest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'MUHTASARI WA FAIDA HALISI' : 'NET PROFIT SUMMARY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _PlUi.lightTeal.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    controller.formatTsh(controller.netProfit.value),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                if (controller.trendPctLabel.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      controller.trendPctLabel.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _PlUi.lightTeal.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(BuildContext context) {
    final u = _PlUi(context);
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: u.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.cardShadow,
          border: u.dark
              ? Border.all(color: context.tokens.elevatedSurface.withValues(alpha: 0.8))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: u.forestOnBg, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSw ? 'Muhtasari wa mapato' : 'Revenue Breakdown',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: u.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _PlUi.lightTeal.withValues(alpha: u.dark ? 0.2 : 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.revenueRangeBadge(isSw: _isSw),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: u.forestOnBg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _revenueRow(
              context,
              icon: Icons.home_outlined,
              title: _isSw ? 'Mapato ya kodi' : 'Rent Income',
              subtitle: _isSw
                  ? '${controller.rentTransactionCount.value} mikataba hai'
                  : '${controller.rentTransactionCount.value} Active Bookings',
              amount: controller.formatTsh(controller.rentIncome.value),
            ),
            const SizedBox(height: 14),
            _revenueRow(
              context,
              icon: Icons.cleaning_services_outlined,
              title: _isSw ? 'Ada za huduma' : 'Service Charges',
              subtitle: _isSw ? 'Usafi na concierge' : 'Cleaning & concierge',
              amount: controller.formatTsh(controller.serviceIncome.value),
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSw ? 'JUMLA YA MAPATO' : 'TOTAL REVENUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: u.muted,
                  ),
                ),
                Text(
                  controller.formatTsh(controller.totalRevenue.value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: u.forestOnBg,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _revenueRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    final u = _PlUi(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: RentTheme.sectionMist.withValues(alpha: u.dark ? 0.15 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: u.forestOnBg, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: u.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: u.muted),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: u.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _expenseCard(BuildContext context) {
    final u = _PlUi(context);
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: u.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.cardShadow,
          border: u.dark
              ? Border.all(color: context.tokens.elevatedSurface.withValues(alpha: 0.8))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: u.forestOnBg, size: 22),
                const SizedBox(width: 8),
                Text(
                  _isSw ? 'Muhtasari wa gharama' : 'Expense Breakdown',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: u.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...controller.expenseLinesForUi(isSw: _isSw).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(line.icon, color: u.muted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: u.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          controller.formatTsh(line.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: u.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSw ? 'JUMLA YA GHARAMA' : 'TOTAL EXPENSES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: u.muted,
                  ),
                ),
                Text(
                  controller.formatTsh(controller.totalExpenses.value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _PlUi.expenseRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _efficiencyCard(BuildContext context) {
    final u = _PlUi(context);
    return Obx(
      () {
        final margin = controller.profitMarginPct.value.clamp(0.0, 100.0);
        final rest = (100.0 - margin).clamp(0.0, 100.0);
        final hasRev = controller.totalRevenue.value > 0.01;
        final grey = u.dark ? const Color(0xFF48484A) : const Color(0xFFE0E0E0);

        final List<PieChartSectionData> sections;
        if (!hasRev) {
          sections = [
            PieChartSectionData(
              value: 100,
              color: grey,
              radius: 52,
              showTitle: false,
            ),
          ];
        } else if (margin <= 0.5) {
          sections = [
            PieChartSectionData(
              value: 100,
              color: grey,
              radius: 52,
              showTitle: false,
            ),
          ];
        } else if (margin >= 99.5) {
          sections = [
            PieChartSectionData(
              value: 100,
              color: _PlUi.forest,
              radius: 52,
              showTitle: false,
            ),
          ];
        } else {
          sections = [
            PieChartSectionData(
              value: margin,
              color: _PlUi.forest,
              radius: 52,
              showTitle: false,
            ),
            PieChartSectionData(
              value: rest < 0.5 ? 0.5 : rest,
              color: grey,
              radius: 52,
              showTitle: false,
            ),
          ];
        }

        final label = hasRev
            ? '${margin.round()}% ${_isSw ? 'HAZINA YA FAIDA' : 'PROFIT MARGIN'}'
            : (_isSw ? 'Hakuna mapato' : 'No revenue');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: u.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: u.cardShadow,
            border: u.dark
                ? Border.all(color: context.tokens.elevatedSurface.withValues(alpha: 0.8))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSw ? 'UWIANO WA UFAHAMILIVU' : 'EFFICIENCY RATIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: u.muted,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 58,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                      duration: const Duration(milliseconds: 200),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: u.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(_PlUi.forest, _isSw ? 'MAPATO 100%' : 'REVENUE 100%'),
                  const SizedBox(width: 20),
                  _legendDot(
                    _PlUi.expenseRed,
                    _isSw
                        ? 'GHARAMA ${controller.expenseRatioPct.value.round()}%'
                        : 'EXPENSES ${controller.expenseRatioPct.value.round()}%',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color c, String text) {
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
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _aiInsightsCard(BuildContext context) {
    final u = _PlUi(context);
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _PlUi.forest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isSw ? 'MAARIFA YA AI' : 'AI INSIGHTS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (controller.insightLines.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isSw ? 'Inapakia maarifa…' : 'Loading insights…',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              )
            else
              ...controller.insightLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    final u = _PlUi(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.onDownloadPdf,
            style: FilledButton.styleFrom(
              backgroundColor: _PlUi.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.download_outlined, size: 22),
            label: Text(
              _isSw ? 'Pakua ripoti ya PDF' : 'Download PDF Report',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => controller.onShareWithAccountant(),
            style: FilledButton.styleFrom(
              backgroundColor: u.dark ? context.tokens.elevatedSurface : const Color(0xFFE8E8E8),
              foregroundColor: u.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.share_outlined, size: 22),
            label: Text(
              _isSw ? 'Shiriki na mhasibu' : 'Share with Accountant',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
