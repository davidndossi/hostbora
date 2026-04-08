import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_listing_details_controller.dart';

class RentListingDetailsView extends BaseView<RentListingDetailsController> {
  RentListingDetailsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Maelezo ya Orodha' : 'Listing details');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya orodha bado.' : 'No listing data available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Maelezo' : 'Details',
              _isSw ? 'Muhtasari wa orodha' : 'Listing snapshot',
              subtitle: _isSw
                  ? 'Uhusiano wa sasa wa mali na mpangaji kutoka rekodi za ndani.'
                  : 'Current property and tenant linkage from local records.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Jumla ya mali' : 'Total properties', value: '${d.properties}', icon: Icons.home_work_outlined, accent: Colors.teal),
              rentMetricTile(label: _isSw ? 'Wapangaji waliounganishwa' : 'Linked tenants', value: '${d.tenants}', icon: Icons.people_outline, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: _isSw ? 'Hali ya orodha' : 'Listing status',
              message: d.properties == 0
                  ? (_isSw
                      ? 'Bado hakuna mali. Ongeza mali kuanza kusimamia maarifa ya kiwango cha orodha.'
                      : 'No properties yet. Add a property to start managing listing-level insights.')
                  : (_isSw
                      ? 'Tumia vitendo vya kiwango cha orodha kusimamia tahadhari za malipo, vitendo vya mpangaji na uboreshaji wa mkataba.'
                      : 'Use listing-level actions to manage payment alerts, tenant actions, and renewals.'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.onUnitPrimaryAction,
              child: Text(_isSw ? 'Fungua tahadhari za malipo' : 'Open payment alerts'),
            ),
          ],
        );
      });
}
