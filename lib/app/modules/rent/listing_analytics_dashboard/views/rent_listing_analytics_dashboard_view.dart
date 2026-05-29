import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/rent_base_view.dart';
import '../controllers/rent_listing_analytics_dashboard_controller.dart';

class _AnalyticsUi {
  _AnalyticsUi(this.context);
  final BuildContext context;

  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF0F6C69);
  static const Color maroon = Color(0xFF6E3027);
  static const Color olive = Color(0xFF2D3E35);

  Color get bg => dark ? _t.scaffoldBackgroundColor : const Color(0xFFF7F6F2);
  Color get card => dark ? _t.cardColor : Colors.white;
  Color get tintCard => dark ? context.tokens.cardBackground : const Color(0xFFF1F1ED);
  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF161616);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
  Color get subtle => dark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);
  Color get accentLabel => dark ? const Color(0xFFFFAB91) : const Color(0xFF7B311A);

  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class RentListingAnalyticsDashboardView
    extends RentBaseView<RentListingAnalyticsDashboardController> {
  RentListingAnalyticsDashboardView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static final NumberFormat _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => _AnalyticsUi(context).bg;

  @override
  bool extendBodyBehindAppBar() => true;

  @override
  Widget body(BuildContext context) {
    final u = _AnalyticsUi(context);
    return Obx(() {
      if (controller.loadingRealData.value) {
        return const DefaultScreenSkeleton();
      }
      final d = controller.realData.value;
      if (d == null) {
        return Center(
          child: Text(
            _isSw
                ? 'Hakuna data ya uchanganuzi wa orodha bado.'
                : 'No listing analytics data available yet.',
            style: TextStyle(color: u.muted),
          ),
        );
      }

      final occupancyRate = d.properties == 0
          ? 0.0
          : ((d.tenants / d.properties) * 100).clamp(0, 100).toDouble();
      final revenue = d.incomeTotal;
      final avgDailyRate = (revenue / 30).clamp(0, double.infinity).toDouble();

      return RefreshIndicator(
        color: _AnalyticsUi.teal,
        onRefresh: controller.loadRealDataSnapshot,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 30),
          children: [
            const SizedBox(height: 20),
            Text(
              _isSw ? 'PERFORMANCE OVERVIEW' : 'PERFORMANCE OVERVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: u.muted,
              ),
            ),
            // const SizedBox(height: 8),
            // Text(
            //   controller.listingTitleFromRoute,
            //   style: TextStyle(
            //     fontFamily: 'serif',
            //     fontSize: 38,
            //     fontWeight: FontWeight.w700,
            //     height: 1.0,
            //     color: u.onSurface,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Text(
            //   _isSw ? 'Arusha, Tanzania' : 'Arusha, Tanzania',
            //   style: TextStyle(fontSize: 12, color: u.muted),
            // ),
            // const SizedBox(height: 12),
            // _listingPicker(u),
            const SizedBox(height: 14),
            _occupancyCard(u, occupancyRate),
            const SizedBox(height: 12),
            _tealRevenueCard(u, revenue),
            const SizedBox(height: 12),
            _avgDailyRateCard(u, avgDailyRate),
            const SizedBox(height: 18),
            _revenueDynamicsCard(u, occupancyRate, revenue),
            const SizedBox(height: 14),
            // _bookingChannelsCard(u),
            // const SizedBox(height: 14),
            _topMonthsCard(u, occupancyRate),
            // const SizedBox(height: 14),
            // _predictiveOccupancyCard(u, occupancyRate),
          ],
        ),
      );
    });
  }

  Widget _topBar(_AnalyticsUi u) {
    return Row(
      children: [
        Icon(Icons.home_outlined, size: 18, color: u.onSurface),
        const SizedBox(width: 6),
        Text(
          'Analytics',
          style: TextStyle(
            color: u.onSurface,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Icon(Icons.settings_outlined, size: 18, color: u.onSurface),
      ],
    );
  }

  Widget _listingPicker(_AnalyticsUi u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: u.subtle.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.listingTitleFromRoute,
              style: TextStyle(color: u.onSurface, fontSize: 13),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: u.muted),
        ],
      ),
    );
  }

  Widget _occupancyCard(_AnalyticsUi u, double occupancyRate) {
    return _plainCard(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSw ? 'OCCUPANCY RATE' : 'OCCUPANCY RATE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: u.muted,
                ),
              ),
              const Spacer(),
              Text(
                '${occupancyRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: u.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${occupancyRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 0.9,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isSw ? 'Mwenendo wa miezi 6 iliyopita' : 'Growth in the last 6 months',
            style: TextStyle(fontSize: 11, color: u.muted),
          ),
        ],
      ),
    );
  }

  Widget _tealRevenueCard(_AnalyticsUi u, double revenue) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AnalyticsUi.teal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSw ? 'TOTAL REVENUE' : 'TOTAL REVENUE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_graph_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: _money.format(revenue.round()),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' TSh',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isSw
                ? 'Mabadiliko +12% mwezi huu'
                : '12% growth compared to the previous month',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avgDailyRateCard(_AnalyticsUi u, double avgDailyRate) {
    return _plainCard(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSw ? 'AVG DAILY RATE' : 'AVG DAILY RATE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: u.muted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D5D1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Stable',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF7B311A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: u.onSurface),
              children: [
                TextSpan(
                  text: _money.format(avgDailyRate.round()),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' TSh',
                  style: TextStyle(fontSize: 15, color: u.muted),
                ),
              ],
            ),
          ),
          Text(
            _isSw ? 'Wastani wa siku 30' : 'Average over 30 days',
            style: TextStyle(fontSize: 11, color: u.muted),
          ),
        ],
      ),
    );
  }

  Widget _revenueDynamicsCard(_AnalyticsUi u, double occ, double revenue) {
    return _plainCard(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Revenue Dynamics' : 'Revenue Dynamics',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          Text(
            _isSw
                ? 'Mwenendo wa utendaji wa mapato'
                : 'Performance trajectory of revenue expected',
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
          const SizedBox(height: 10),
          Obx(() => Row(
                children: [
                  _rangeChip(u, 0, _isSw ? 'Siku' : 'Daily'),
                  const SizedBox(width: 6),
                  _rangeChip(u, 1, _isSw ? 'Wiki' : 'Weekly'),
                  const SizedBox(width: 6),
                  _rangeChip(u, 2, _isSw ? 'Mwezi' : 'Monthly'),
                ],
              )),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: Obx(() => _chart(u, occ, revenue))),
        ],
      ),
    );
  }

  Widget _rangeChip(_AnalyticsUi u, int idx, String label) {
    final selected = controller.trendRangeIndex.value == idx;
    return GestureDetector(
      onTap: () => controller.setTrendRange(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _AnalyticsUi.teal : u.tintCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : u.muted,
          ),
        ),
      ),
    );
  }

  Widget _chart(_AnalyticsUi u, double occ, double revenue) {
    final r = controller.trendRangeIndex.value;
    final base = (revenue <= 0 ? 5000000 : revenue) / (r == 0 ? 6 : r == 1 ? 8 : 10);
    final lineA = List<double>.generate(
      6,
      (i) => base * (0.7 + (i * 0.11)) + (occ * 4200) - (r * 50000),
    );
    final lineB = List<double>.generate(
      6,
      (i) => base * (0.58 + (i * 0.09)) + ((i.isEven ? 1 : -1) * 120000) - (r * 30000),
    );
    final lineC = List<double>.generate(
      6,
      (i) => base * (0.64 + (i * 0.1)) + ((i < 3 ? i : 5 - i) * 90000),
    );

    List<FlSpot> toSpots(List<double> rows) =>
        List.generate(rows.length, (i) => FlSpot(i.toDouble(), rows[i]));
    final all = [...lineA, ...lineB, ...lineC];
    final minY = all.reduce((a, b) => a < b ? a : b) * 0.86;
    final maxY = all.reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: u.subtle.withValues(alpha: 0.28), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                const xs = ['MON', 'TUE', 'WED', 'THU', 'SAT', 'SUN'];
                final i = v.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    (i >= 0 && i < xs.length) ? xs[i] : '',
                    style: TextStyle(fontSize: 9, color: u.muted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: _AnalyticsUi.teal,
            barWidth: 3,
            spots: toSpots(lineA),
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            isCurved: true,
            color: _AnalyticsUi.olive,
            barWidth: 3,
            spots: toSpots(lineB),
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            isCurved: true,
            color: _AnalyticsUi.maroon,
            barWidth: 3,
            spots: toSpots(lineC),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
    );
  }

  Widget _bookingChannelsCard(_AnalyticsUi u) {
    final channels = [
      ('Airbnb Marketplace', 54),
      ('Direct Reservation', 28),
      ('Booking.com', 12),
      (_isSw ? 'Nyingine' : 'Others', 6),
    ];
    return _plainCard(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Booking Channels' : 'Booking Channels',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          Text(
            _isSw ? 'Mchanganyo wa vyanzo vya uhifadhi' : 'Traffic mix from reservations sources',
            style: TextStyle(fontSize: 12, color: u.muted),
          ),
          const SizedBox(height: 12),
          ...channels.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(c.$1, style: TextStyle(fontSize: 12, color: u.onSurface)),
                  ),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: c.$2 / 100,
                        minHeight: 7,
                        backgroundColor: u.tintCard,
                        color: _AnalyticsUi.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${c.$2}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: u.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: u.dark ? const Color(0xFF3A2D2A) : const Color(0xFFFDF0EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: u.accentLabel, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSw
                        ? 'Mabadiliko kwenye njia za uhifadhi yameonekana wiki hii.'
                        : 'Recent booking channel changes detected in the past 7 days.',
                    style: TextStyle(fontSize: 11, color: u.accentLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topMonthsCard(_AnalyticsUi u, double occupancyRate) {
    return _plainCard(
      u,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Top Performing Months' : 'Top Performing Months',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _monthBox(u, _isSw ? 'December' : 'December', '${(occupancyRate + 4).toStringAsFixed(0)}% Occupancy')),
              const SizedBox(width: 10),
              Expanded(child: _monthBox(u, _isSw ? 'August' : 'August', '${(occupancyRate - 7).clamp(0, 100).toStringAsFixed(0)}% Occupancy')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthBox(_AnalyticsUi u, String month, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: u.tintCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(month.toUpperCase(), style: TextStyle(fontSize: 10, color: u.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(month, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: u.onSurface)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: u.muted)),
        ],
      ),
    );
  }

  Widget _predictiveOccupancyCard(_AnalyticsUi u, double occupancyRate) {
    final projected = (occupancyRate + 3.5).clamp(0, 99.9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.tintCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Predictive Occupancy' : 'Predictive Occupancy',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSw
                ? 'Utabiri wa mwezi ujao unaonyesha ujazaji wa takriban ${projected.toStringAsFixed(1)}%.'
                : 'Machine model projects occupancy around ${projected.toStringAsFixed(1)}% over the next 30 days.',
            style: TextStyle(fontSize: 12, color: u.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _AnalyticsUi.teal,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(_isSw ? 'Anzisha Utabiri wa AI' : 'Activate Predictive AI'),
          ),
        ],
      ),
    );
  }

  Widget _plainCard(_AnalyticsUi u, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: u.shadow,
        border: u.dark ? Border.all(color: const Color(0xFF48484A)) : null,
      ),
      child: child,
    );
  }
}
