import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_listing_analytics_dashboard_controller.dart';

class RentListingAnalyticsDashboardView
    extends BaseView<RentListingAnalyticsDashboardController> {
  RentListingAnalyticsDashboardView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => const Color(0xFFF9F8F6);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 34,
        leading: const SizedBox(),
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: Color(0xFF0E3B5A),
              child: Icon(Icons.person, size: 10, color: Colors.white),
            ),
            SizedBox(width: 6),
            Text(
              'Analytics',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF134B63),
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.settings, size: 16, color: Color(0xFF005B60)),
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERFORMANCE OVERVIEW',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 2,
                    color: Color(0xFF6E6E6E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Serengeti\nVista',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    height: 1.1,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: Color(0xFF6B6B6B)),
                    SizedBox(width: 3),
                    Text('Arusha, Tanzania',
                        style: TextStyle(fontSize: 10, color: Color(0xFF6B6B6B))),
                  ],
                ),
                const SizedBox(height: 10),
                _analyticsDropdown('The Serengeti Vista'),
                const SizedBox(height: 10),
                _analyticsCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('OCCUPANCY RATE',
                              style: TextStyle(
                                  fontSize: 8,
                                  letterSpacing: 1.1,
                                  color: Color(0xFF6D6D6D),
                                  fontWeight: FontWeight.w700)),
                          Spacer(),
                          _TinyPill(text: '+4.2%'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('92.4',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 21)),
                      Text('%',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      SizedBox(height: 2),
                      Text('vs Last Month +3.8%',
                          style: TextStyle(fontSize: 8, color: Color(0xFF7A7A7A))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  color: const Color(0xFF01545D),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('TOTAL REVENUE',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700)),
                          Spacer(),
                          Icon(Icons.account_balance_wallet_outlined,
                              color: Colors.white70, size: 14),
                        ],
                      ),
                      SizedBox(height: 7),
                      Text('14,250,000',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Tsh',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                      SizedBox(height: 2),
                      Text('Current Day',
                          style: TextStyle(color: Colors.white70, fontSize: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('AVG DAILY RATE',
                              style: TextStyle(
                                  fontSize: 8,
                                  letterSpacing: 1.1,
                                  color: Color(0xFF6D6D6D),
                                  fontWeight: FontWeight.w700)),
                          Spacer(),
                          _TinyPill(text: 'Stable'),
                        ],
                      ),
                      SizedBox(height: 7),
                      Text('425,000',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Tsh', style: TextStyle(fontSize: 11)),
                      SizedBox(height: 2),
                      Text('Per Night Rate',
                          style: TextStyle(fontSize: 8, color: Color(0xFF7A7A7A))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Dynamics',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 19)),
                      const Text('Performance trends for your luxury property',
                          style: TextStyle(fontSize: 10, color: Color(0xFF777777))),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          _ChipPeriod('Daily', selected: true),
                          SizedBox(width: 6),
                          _ChipPeriod('Weekly'),
                          SizedBox(width: 6),
                          _ChipPeriod('Monthly'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            CustomPaint(
                                size: const Size(double.infinity, 120),
                                painter: _RevenueLinePainter()),
                            const Positioned(
                              top: 8,
                              right: 50,
                              child: _GraphTag(text: 'May  • 1.9M Tsh'),
                            ),
                            const Positioned(
                              bottom: 8,
                              left: 14,
                              right: 14,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('MON',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                  Text('TUE',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                  Text('WED',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                  Text('THU',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                  Text('FRI',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                  Text('SAT',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF888888))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Channels',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 19)),
                      Text('Distribution & Marketplace Performance',
                          style: TextStyle(fontSize: 10, color: Color(0xFF777777))),
                      SizedBox(height: 10),
                      _ChannelRow(name: 'Airbnb Marketplace', pct: '54%'),
                      _ChannelRow(name: 'Direct Reservations', pct: '28%'),
                      _ChannelRow(name: 'Booking.com', pct: '12%'),
                      _ChannelRow(name: 'Others', pct: '6%'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  color: const Color(0xFFF9EEEC),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFFF6D9D2),
                          child: Icon(Icons.lightbulb_outline,
                              size: 14, color: Color(0xFFAD4E37))),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OPPORTUNITY',
                                style: TextStyle(
                                    fontSize: 8,
                                    letterSpacing: 1.4,
                                    color: Color(0xFF9A5A4E),
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('Low Booking on Fridays',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3A1F1A))),
                            Text('Increase by night and test promos',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF7A524A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Performing Months',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 19)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _MonthTile(
                                  month: 'December',
                                  subtitle: '+18% Occupancy')),
                          SizedBox(width: 8),
                          Expanded(
                              child: _MonthTile(
                                  month: 'August', subtitle: '+15% Occupancy')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _analyticsCard(
                  color: const Color(0xFFEAF4F3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Predictive Occupancy',
                          style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 19)),
                      const SizedBox(height: 4),
                      const Text(
                        'Upcoming peak season indicates a 15%\nincrease in demand. Apply luxury pricing\nstrategy',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF4E5E5E), height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006A6F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Enable Strategy',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        _analyticsBottomNav(),
      ],
    );
  }
}

Widget _analyticsCard({required Widget child, Color color = Colors.white}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

Widget _analyticsDropdown(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F1EF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF444444)))),
        const Icon(Icons.expand_more, size: 16, color: Color(0xFF555555)),
      ],
    ),
  );
}

Widget _analyticsBottomNav() {
  return Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE8E6E1))),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _AnalyticsNav(icon: Icons.home_outlined, label: 'PROPERTIES'),
          _AnalyticsNav(icon: Icons.calendar_today_outlined, label: 'BOOKINGS'),
          _AnalyticsNav(icon: Icons.insights_outlined, label: 'INSIGHTS'),
          _AnalyticsNav(
              icon: Icons.analytics_outlined, label: 'ANALYTICS', selected: true),
        ],
      ),
    ),
  );
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0EE), borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 8, color: Color(0xFF6A6A6A), fontWeight: FontWeight.w700)),
    );
  }
}

class _ChipPeriod extends StatelessWidget {
  const _ChipPeriod(this.label, {this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF005D5D) : const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: selected ? Colors.white : const Color(0xFF555555),
              fontWeight: FontWeight.w700)),
    );
  }
}

class _GraphTag extends StatelessWidget {
  const _GraphTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.white)),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.name, required this.pct});
  final String name;
  final String pct;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F1),
                  borderRadius: BorderRadius.circular(7)),
              child: Text(name, style: const TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 30,
              child: Text(pct,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.month, required this.subtitle});
  final String month;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F3F1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PEAK', style: TextStyle(fontSize: 8, color: Color(0xFF7A7A7A))),
          const SizedBox(height: 3),
          Text(month,
              style: const TextStyle(
                  fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF6A6A6A))),
        ],
      ),
    );
  }
}

class _AnalyticsNav extends StatelessWidget {
  const _AnalyticsNav({required this.icon, required this.label, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF005D5D) : const Color(0xFF767676);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 7.5, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RevenueLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()
      ..color = const Color(0xFF006A6F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final maroon = Paint()
      ..color = const Color(0xFF5A2222)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final tealPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.75)
      ..cubicTo(size.width * 0.2, size.height * 0.2, size.width * 0.34,
          size.height * 0.95, size.width * 0.48, size.height * 0.45)
      ..cubicTo(size.width * 0.54, size.height * 0.25, size.width * 0.58,
          size.height * 0.55, size.width * 0.62, size.height * 0.65);
    final maroonPath = Path()
      ..moveTo(size.width * 0.62, size.height * 0.65)
      ..cubicTo(size.width * 0.72, size.height * 0.35, size.width * 0.8,
          size.height * 0.2, size.width * 0.9, size.height * 0.7);
    canvas.drawPath(tealPath, teal);
    canvas.drawPath(maroonPath, maroon);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
