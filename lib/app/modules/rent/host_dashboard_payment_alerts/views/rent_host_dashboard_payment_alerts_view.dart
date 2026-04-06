import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

class RentHostDashboardPaymentAlertsView extends BaseView<RentHostDashboardPaymentAlertsController> {
  RentHostDashboardPaymentAlertsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Host dashboard payment alerts');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No payment alerts data available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Alerts', 'Payment watchlist', subtitle: 'Collections and lease-risk indicators from current tenant records.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Tracked tenants', value: '${d.tenants}', icon: Icons.people_alt_outlined, accent: Colors.blue),
              rentMetricTile(label: 'Renewals soon', value: '${d.expiringLeasesIn30Days}', icon: Icons.event_note_outlined, accent: Colors.deepOrange),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: 'Reminder readiness',
              message: d.tenants == 0
                  ? 'No tenants in local records. Add tenant records to activate payment alert workflows.'
                  : 'Payment reminders can be triggered directly from this dashboard or from tenant ledger.',
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: controller.openSetReminder, child: const Text('Set payment reminder')),
          ],
        );
      });
}
