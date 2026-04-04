import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

/// **The Concierge — Estate Manager** dashboard (cream, `#005B5C` teal, editorial type).
abstract class _HostDash {
  static const Color primaryTeal = Color(0xFF005B5C);
  static const Color urgentRed = Color(0xFFC62828);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color labelGray = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFE8E6E1);
  static const Color proTipOrange = Color(0xFFE65100);
  static const Color statsCardBg = Color(0xFFEEEDE8);

  static TextStyle serifHeadline(double size, {FontWeight w = FontWeight.w700, Color? color}) =>
      TextStyle(fontSize: size, height: 1.1, fontWeight: w, color: color ?? charcoal);

  static TextStyle serifMetric(double size, {Color? color}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color ?? charcoal);

  static const TextStyle sansLabel = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    color: labelGray,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sansBody = TextStyle(fontSize: 12, color: labelGray, height: 1.35);
}

class RentHostDashboardPaymentAlertsView extends BaseView<RentHostDashboardPaymentAlertsController> {
  RentHostDashboardPaymentAlertsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Estate Manager');

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('EVERGREEN ESTATE', style: _HostDash.sansLabel.copyWith(fontSize: 10)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => controller.openProfitAnalysisDashboard(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              backgroundColor: const Color(0xFFF3F2EF),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('FINANCIAL ANALYSIS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 14),
        _statsStrip(),
        const SizedBox(height: 20),
        _urgentSectionHeader(),
        const SizedBox(height: 12),
        _featuredTenantCard(),
        const SizedBox(height: 12),
        _proTipBanner(),
        const SizedBox(height: 10),
        _miniTenantCard(
          name: 'Babatunde Kwasi',
          unit: 'Garden Villa 09',
          balance: 'Tsh 1,250,000',
          due: 'July 18',
        ),
        const SizedBox(height: 8),
        _miniTenantCard(
          name: 'Chen Hu',
          unit: 'Skylecourt 103',
          balance: 'Tsh 890,000',
          due: 'July 22',
        ),
        const SizedBox(height: 12),
        _monitorNewTenantCard(),
        const SizedBox(height: 22),
        Text('Estate Overview', style: _HostDash.serifHeadline(24)),
        const SizedBox(height: 12),
        _overviewCard(
          icon: Icons.bar_chart_rounded,
          label: 'Monthly Revenue',
          value: 'Tsh 42.8M',
          valueStyle: _HostDash.serifMetric(20),
          trailing: _greenBadge('+12.4%'),
        ),
        const SizedBox(height: 10),
        _overviewCard(
          icon: Icons.calendar_month_outlined,
          label: 'Active Bookings',
          value: '284 Units',
          valueStyle: _HostDash.serifMetric(20),
          trailing: _greyBadge('target 300'),
        ),
        const SizedBox(height: 10),
        _overviewCard(
          icon: Icons.pie_chart_outline_rounded,
          label: 'Occupancy Rate',
          value: '94.2%',
          valueStyle: _HostDash.serifMetric(22, color: _HostDash.primaryTeal),
          trailing: _avatarStack(),
        ),
      ],
    );
  }

  Widget _statsStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _HostDash.statsCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _HostDash.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricItem(
            label: 'Current Occupancy',
            value: '94.2%',
            valueStyle: _HostDash.serifMetric(24, color: _HostDash.primaryTeal),
          ),
          _MetricItem(
            label: 'Daily Revenue',
            value: 'Tsh 1.2M',
            valueStyle: _HostDash.serifMetric(22, color: _HostDash.primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _urgentSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 3,
            height: 24,
            decoration: const BoxDecoration(
              color: _HostDash.urgentRed,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Urgent: Partial Payments',
            style: _HostDash.serifHeadline(21),
          ),
        ),
        GestureDetector(
          onTap: controller.onViewAllDelinquencies,
          child: Text(
            'View All\nDelinquencies',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _HostDash.primaryTeal,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _estateCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _HostDash.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _featuredTenantCard() {
    return _estateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: _HostDash.border,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE8E4DD),
              child: Icon(Icons.person, size: 44, color: _HostDash.charcoal.withValues(alpha: 0.45)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Amara Okafor', style: _HostDash.serifHeadline(22)),
          const SizedBox(height: 4),
          const Text(
            'Premier Suite 402 • Evergreen Estate',
            textAlign: TextAlign.center,
            style: _HostDash.sansBody,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _smallMeta(
                    'Remaining Balance',
                    'Tsh 400,000',
                    valueStyle: _HostDash.serifMetric(15, color: _HostDash.charcoal),
                  ),
                ),
                Expanded(
                  child: _smallMeta(
                    'Completion Date',
                    'July 15, 2024',
                    valueStyle: _HostDash.serifMetric(15, color: _HostDash.charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.onNotifyFeaturedTenant,
              style: FilledButton.styleFrom(
                backgroundColor: _HostDash.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.notifications_active_outlined, size: 20),
              label: const Text('Notify', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.openSetReminder,
              style: OutlinedButton.styleFrom(
                foregroundColor: _HostDash.charcoal,
                backgroundColor: const Color(0xFFF0EEEA),
                side: BorderSide(color: _HostDash.charcoal.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proTipBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 118,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _HostDash.primaryTeal,
                    Color.lerp(_HostDash.primaryTeal, Colors.black, 0.35)!,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -16,
              bottom: -20,
              child: Opacity(
                opacity: 0.2,
                child: Icon(Icons.account_balance, size: 140, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _HostDash.proTipOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PRO TIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Optimize Cash Flow', style: _HostDash.serifHeadline(19, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Automate reminders for partial payments to reduce administrative overhead by 40%',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTenantCard({
    required String name,
    required String unit,
    required String balance,
    required String due,
  }) {
    return _estateCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _HostDash.border,
                child: Icon(Icons.person, size: 20, color: _HostDash.charcoal.withValues(alpha: 0.45)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _HostDash.serifHeadline(17)),
                    Text(unit, style: _HostDash.sansBody.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallMeta('Balance', balance, valueStyle: _HostDash.serifMetric(13)),
              ),
              Expanded(
                child: _smallMeta('Due Date', due, valueStyle: _HostDash.serifMetric(13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.onSendLateNotice,
              style: OutlinedButton.styleFrom(
                foregroundColor: _HostDash.charcoal,
                backgroundColor: const Color(0xFFF5F3EF),
                side: const BorderSide(color: _HostDash.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: const Text(
                'SEND LATE NOTICE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitorNewTenantCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.onMonitorNewTenant,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          foregroundPainter: _DashedRoundedRectPainter(
            color: _HostDash.border,
            radius: 14,
            strokeWidth: 1.2,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _HostDash.labelGray.withValues(alpha: 0.35)),
                    color: Colors.white,
                  ),
                  child: Icon(Icons.add, size: 24, color: _HostDash.labelGray),
                ),
                const SizedBox(height: 10),
                Text(
                  'MONITOR NEW TENANT',
                  style: _HostDash.sansLabel.copyWith(fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String label,
    required String value,
    required TextStyle valueStyle,
    required Widget trailing,
  }) {
    return _estateCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: _HostDash.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: _HostDash.sansLabel.copyWith(fontSize: 9, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(value, style: valueStyle),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  static Widget _greenBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
    );
  }

  static Widget _greyBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _HostDash.labelGray),
      ),
    );
  }

  static Widget _avatarStack() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 2; i++)
          Align(
            widthFactor: i == 0 ? 1.0 : 0.62,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: _HostDash.border,
                child: Icon(Icons.person, size: 14, color: _HostDash.labelGray),
              ),
            ),
          ),
      ],
    );
  }

  Widget _smallMeta(String label, String value, {TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: _HostDash.sansLabel.copyWith(fontSize: 8, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _HostDash.charcoal),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value, required this.valueStyle});

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: _HostDash.sansLabel.copyWith(fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashLen = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(d, next),
          Paint()
            ..color = color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke,
        );
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}
