import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_analysis_controller.dart';

class RentPropertyRoiAnalysisView extends BaseView<RentPropertyRoiAnalysisController> {
  RentPropertyRoiAnalysisView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Property ROI analysis');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No ROI data available yet.'));
        final roi = d.expenseTotal <= 0 ? 0.0 : (d.netProfit / d.expenseTotal) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('ROI', 'Return analysis', subtitle: 'Property return metrics derived from recorded income and costs.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Properties', value: '${d.properties}', icon: Icons.apartment_outlined, accent: Colors.teal),
              rentMetricTile(label: 'ROI', value: '${roi.toStringAsFixed(2)}%', icon: Icons.query_stats_outlined, accent: Colors.deepPurple),
              rentMetricTile(label: 'Net value', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.monetization_on_outlined, accent: Colors.indigo),
            ]),
          ],
        );
      });
}
