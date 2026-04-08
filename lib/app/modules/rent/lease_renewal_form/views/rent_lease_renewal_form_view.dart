import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_lease_renewal_form_controller.dart';

class RentLeaseRenewalFormView extends BaseView<RentLeaseRenewalFormController> {
  RentLeaseRenewalFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Fomu ya Uhuishaji wa Mkataba' : 'Lease renewal form');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna rekodi za wapangaji bado.' : 'No tenant records available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Uhuishaji' : 'Renewals',
              _isSw ? 'Mzunguko wa mkataba' : 'Lease cycle',
              subtitle: _isSw
                  ? 'Fuatilia uhuishaji unaokuja na mzigo wa mikataba ya wapangaji.'
                  : 'Track upcoming renewals and tenant contract workload.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Wapangaji hai' : 'Active tenants', value: '${d.tenants}', icon: Icons.groups_outlined, accent: Colors.blueGrey),
              rentMetricTile(label: _isSw ? 'Yanayodaiwa ndani ya siku 30' : 'Due in 30 days', value: '${d.expiringLeasesIn30Days}', icon: Icons.schedule_outlined, accent: Colors.deepOrange),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: _isSw ? 'Mzigo wa uhuishaji' : 'Renewal workload',
              message: d.expiringLeasesIn30Days == 0
                  ? (_isSw ? 'Hakuna uhuishaji wa mkataba ndani ya siku 30 zijazo.' : 'No lease renewals due in the next 30 days.')
                  : (_isSw
                      ? '${d.expiringLeasesIn30Days} mkataba/mikataba inahitaji ufuatiliaji wa uhuishaji katika mzunguko huu.'
                      : '${d.expiringLeasesIn30Days} lease(s) require renewal follow-up this cycle.'),
            ),
          ],
        );
      });
}
