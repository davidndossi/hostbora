import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_host_dashboard_payment_alerts_controller.dart';

class RentHostDashboardPaymentAlertsView extends BaseView<RentHostDashboardPaymentAlertsController> {
  RentHostDashboardPaymentAlertsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Tahadhari za Malipo za Dashibodi' : 'Host dashboard payment alerts');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(
              _isSw ? 'Hakuna data ya tahadhari za malipo bado.' : 'No payment alerts data available yet.',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Tahadhari' : 'Alerts',
              _isSw ? 'Orodha ya ufuatiliaji wa malipo' : 'Payment watchlist',
              subtitle: _isSw
                  ? 'Viashiria vya makusanyo na hatari ya mkataba kutoka rekodi za sasa za wapangaji.'
                  : 'Collections and lease-risk indicators from current tenant records.',
            ),
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
            FilledButton(
              onPressed: controller.openSetReminder,
              child: Text(_isSw ? 'Weka kikumbusho cha malipo' : 'Set payment reminder'),
            ),
          ],
        );
      });
}
