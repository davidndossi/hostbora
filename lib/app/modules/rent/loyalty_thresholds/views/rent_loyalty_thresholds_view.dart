import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_loyalty_thresholds_controller.dart';

class RentLoyaltyThresholdsView extends RentBaseView<RentLoyaltyThresholdsController> {
  RentLoyaltyThresholdsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Vizingiti vya Uaminifu' : 'Loyalty thresholds');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const DefaultScreenSkeleton();
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya uaminifu bado.' : 'No loyalty data available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Uaminifu' : 'Loyalty',
              _isSw ? 'Hali ya vizingiti' : 'Threshold status',
              subtitle: _isSw
                  ? 'Ofa hai na kundi la wapangaji wanaostahili kutoka rekodi hai.'
                  : 'Active offers and eligible tenant pool from live records.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Ofa hai' : 'Active offers', value: '${d.loyaltyOffers}', icon: Icons.card_giftcard_outlined, accent: Colors.pink),
              rentMetricTile(label: _isSw ? 'Kundi la wapangaji' : 'Tenant pool', value: '${d.tenants}', icon: Icons.groups_2_outlined, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: _isSw ? 'Pendekezo la kizingiti' : 'Threshold recommendation',
              message: d.loyaltyOffers == 0
                  ? (_isSw
                      ? 'Hakuna ofa za uaminifu zilizowekwa. Bainisha angalau ofa moja kuanzisha ufuatiliaji wa vizingiti.'
                      : 'No loyalty offers configured. Define at least one offer to activate threshold tracking.')
                  : (_isSw
                      ? 'Ofa ziko hai. Endelea kulinganisha vizingiti na malengo ya ujazaji na uhifadhi.'
                      : 'Offers are active. Keep thresholds aligned with occupancy and retention targets.'),
            ),
          ],
        );
      });
}
