import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_lease_renewal_form_controller.dart';

class RentLeaseRenewalFormView extends BaseView<RentLeaseRenewalFormController> {
  RentLeaseRenewalFormView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Lease renewal form');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No tenant records available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Renewals', 'Lease cycle', subtitle: 'Track upcoming renewals and tenant contract workload.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Active tenants', value: '${d.tenants}', icon: Icons.groups_outlined, accent: Colors.blueGrey),
              rentMetricTile(label: 'Due in 30 days', value: '${d.expiringLeasesIn30Days}', icon: Icons.schedule_outlined, accent: Colors.deepOrange),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: 'Renewal workload',
              message: d.expiringLeasesIn30Days == 0
                  ? 'No lease renewals due in the next 30 days.'
                  : '${d.expiringLeasesIn30Days} lease(s) require renewal follow-up this cycle.',
            ),
          ],
        );
      });
}
