import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_listing_analytics_dashboard_controller.dart';

class RentListingAnalyticsDashboardView extends BaseView<RentListingAnalyticsDashboardController> {
  RentListingAnalyticsDashboardView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Dashibodi ya Uchanganuzi wa Orodha' : 'Listing analytics dashboard');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(
              _isSw ? 'Hakuna data ya uchanganuzi wa orodha bado.' : 'No listing analytics data available yet.',
            ),
          );
        }
        final occupancy = d.properties == 0 ? 0.0 : (d.tenants / d.properties) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Orodha' : 'Listings',
              _isSw ? 'Uchanganuzi wa portfolio' : 'Portfolio analytics',
              subtitle: _isSw
                  ? 'Kiashiria hai cha ujazaji na utendaji wa mali zinazofuatiliwa.'
                  : 'Live occupancy proxy and performance across tracked properties.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Orodha' : 'Listings', value: '${d.properties}', icon: Icons.apartment_outlined, accent: Colors.teal),
              rentMetricTile(label: _isSw ? 'Kiashiria cha ujazaji wa wapangaji' : 'Tenant occupancy proxy', value: '${occupancy.toStringAsFixed(1)}%', icon: Icons.insights_outlined, accent: Colors.purple),
              rentMetricTile(label: _isSw ? 'Portfolio halisi' : 'Net portfolio', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.query_stats_outlined, accent: Colors.indigo),
            ]),
          ],
        );
      });
}
