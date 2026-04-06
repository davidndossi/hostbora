import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_listing_details_controller.dart';

class RentListingDetailsView extends BaseView<RentListingDetailsController> {
  RentListingDetailsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Listing details');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No listing data available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Details', 'Listing snapshot', subtitle: 'Current property and tenant linkage from local records.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Total properties', value: '${d.properties}', icon: Icons.home_work_outlined, accent: Colors.teal),
              rentMetricTile(label: 'Linked tenants', value: '${d.tenants}', icon: Icons.people_outline, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: 'Listing status',
              message: d.properties == 0
                  ? 'No properties yet. Add a property to start managing listing-level insights.'
                  : 'Use listing-level actions to manage payment alerts, tenant actions, and renewals.',
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: controller.onUnitPrimaryAction, child: const Text('Open payment alerts')),
          ],
        );
      });
}
