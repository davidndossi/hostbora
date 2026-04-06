import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_estate_manager_dashboard_controller.dart';

class RentEstateManagerDashboardView extends BaseView<RentEstateManagerDashboardController> {
  RentEstateManagerDashboardView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Estate manager dashboard');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No real data available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Overview', 'Estate pulse', subtitle: 'Operations snapshot from live portfolio records.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Properties', value: '${d.properties}', icon: Icons.home_work_outlined, accent: Colors.teal),
              rentMetricTile(label: 'Tenants', value: '${d.tenants}', icon: Icons.people_alt_outlined, accent: Colors.indigo),
              rentMetricTile(label: 'Staff', value: '${d.staff}', icon: Icons.badge_outlined, accent: Colors.deepPurple),
              rentMetricTile(label: 'Maintenance', value: '${d.maintenanceTasks}', icon: Icons.build_outlined, accent: Colors.orange),
            ]),
            const SizedBox(height: 12),
            rentCard(
              child: Column(
                children: [
                  rentKpiRow('Portfolio net', 'TZS ${d.netProfit.toStringAsFixed(0)}'),
                  rentKpiRow('Expiring leases (30 days)', '${d.expiringLeasesIn30Days}'),
                ],
              ),
            ),
          ],
        );
      });
}
