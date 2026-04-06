import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_loyalty_thresholds_controller.dart';

class RentLoyaltyThresholdsView extends BaseView<RentLoyaltyThresholdsController> {
  RentLoyaltyThresholdsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Loyalty thresholds');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No loyalty data available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Loyalty', 'Threshold status', subtitle: 'Active offers and eligible tenant pool from live records.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Active offers', value: '${d.loyaltyOffers}', icon: Icons.card_giftcard_outlined, accent: Colors.pink),
              rentMetricTile(label: 'Tenant pool', value: '${d.tenants}', icon: Icons.groups_2_outlined, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: 'Threshold recommendation',
              message: d.loyaltyOffers == 0
                  ? 'No loyalty offers configured. Define at least one offer to activate threshold tracking.'
                  : 'Offers are active. Keep thresholds aligned with occupancy and retention targets.',
            ),
          ],
        );
      });
}
