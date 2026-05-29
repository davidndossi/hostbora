import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_estate_manager_dashboard_controller.dart';

class RentEstateManagerDashboardView extends RentBaseView<RentEstateManagerDashboardController> {
  RentEstateManagerDashboardView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Dashibodi ya Meneja wa Majengo' : 'Estate manager dashboard');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const DefaultScreenSkeleton();
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data halisi bado.' : 'No real data available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Muhtasari' : 'Overview',
              _isSw ? 'Mdundo wa majengo' : 'Estate pulse',
              subtitle: _isSw
                  ? 'Muhtasari wa uendeshaji kutoka rekodi hai za portfolio.'
                  : 'Operations snapshot from live portfolio records.',
            ),
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
