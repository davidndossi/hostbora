import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

class RentHostDashboardPaymentAlertsView
    extends BaseView<RentHostDashboardPaymentAlertsController> {
  RentHostDashboardPaymentAlertsView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Payment alerts');

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        rentSectionLabel('Requires attention'),
        rentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RentTheme.warnBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(
                        color: RentTheme.warnFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'TZS 450,000',
                    style: TextStyle(fontWeight: FontWeight.w700, color: RentTheme.navy),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sea View Apt — Rent due Mar 1',
                style: TextStyle(color: RentTheme.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        rentCard(
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: RentTheme.teal),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Masaki Duplex — partial payment received',
                  style: TextStyle(color: RentTheme.navy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        rentSectionLabel('This week'),
        rentCard(
          child: const Text(
            'No upcoming payment deadlines for the next 7 days.',
            style: TextStyle(color: RentTheme.muted),
          ),
        ),
      ],
    );
  }
}
