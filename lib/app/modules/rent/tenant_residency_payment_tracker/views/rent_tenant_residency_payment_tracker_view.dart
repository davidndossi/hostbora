import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_residency_payment_tracker_controller.dart';

class RentTenantResidencyPaymentTrackerView
    extends BaseView<RentTenantResidencyPaymentTrackerController> {
  RentTenantResidencyPaymentTrackerView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Residency & payments');

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        rentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Asha M.',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'Unit 4B • Current lease',
                style: TextStyle(color: RentTheme.muted),
              ),
              const Divider(height: 24),
              _step(Icons.check_circle, 'Lease signed', 'Jan 10, 2025', done: true),
              _step(Icons.check_circle, 'Deposit received', 'Jan 8, 2025', done: true),
              _step(Icons.schedule, 'Next rent due', 'Apr 1, 2026', done: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step(IconData icon, String title, String subtitle, {required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: done ? RentTheme.teal : RentTheme.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: const TextStyle(color: RentTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
