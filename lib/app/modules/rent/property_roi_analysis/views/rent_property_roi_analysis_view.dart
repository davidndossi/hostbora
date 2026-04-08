import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../routes/app_pages.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_analysis_controller.dart';

class RentPropertyRoiAnalysisView extends BaseView<RentPropertyRoiAnalysisController> {
  RentPropertyRoiAnalysisView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Uchambuzi wa ROI ya Mali' : 'Property ROI analysis');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya ROI bado.' : 'No ROI data available yet.'),
          );
        }
        final roi = d.expenseTotal <= 0 ? 0.0 : (d.netProfit / d.expenseTotal) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              'ROI',
              _isSw ? 'Uchambuzi wa marejesho' : 'Return analysis',
              subtitle: _isSw
                  ? 'Vipimo vya marejesho ya mali vilivyotokana na mapato na gharama zilizorekodiwa.'
                  : 'Property return metrics derived from recorded income and costs.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Mali' : 'Properties', value: '${d.properties}', icon: Icons.apartment_outlined, accent: Colors.teal),
              rentMetricTile(label: 'ROI', value: '${roi.toStringAsFixed(2)}%', icon: Icons.query_stats_outlined, accent: Colors.deepPurple),
              rentMetricTile(label: _isSw ? 'Thamani halisi' : 'Net value', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.monetization_on_outlined, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: controller.selectedPropertyLabel.value.isEmpty
                  ? (_isSw ? 'Makadirio kwa kila mali' : 'Per-property estimate')
                  : controller.selectedPropertyLabel.value,
              message: controller.hasEstimate
                  ? (_isSw
                      ? 'Makadirio ya neti ya mwaka: TZS ${controller.estimatedAnnualNet.toStringAsFixed(0)} | Makadirio ya ROI: ${controller.estimatedRoiPercent.toStringAsFixed(2)}%'
                      : 'Estimated annual net: TZS ${controller.estimatedAnnualNet.toStringAsFixed(0)} | Estimated ROI: ${controller.estimatedRoiPercent.toStringAsFixed(2)}%')
                  : (_isSw
                      ? 'Bado hakuna makadirio yaliyohifadhiwa kwa mali hii. Ongeza makadirio kuanza kufuatilia ROI kwa kila mali.'
                      : 'No estimate saved yet for this property. Add estimates to start per-property ROI tracking.'),
            ),
            if (controller.selectedPropertyRef.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Get.toNamed(
                    Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
                    parameters: {
                      'propertyRef': controller.selectedPropertyRef.value,
                      'propertyLabel': controller.selectedPropertyLabel.value,
                    },
                  );
                  if (result == true) {
                    await controller.loadAll();
                  }
                },
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(
                  controller.hasEstimate
                      ? (_isSw ? 'Hariri makadirio' : 'Edit estimates')
                      : (_isSw ? 'Ongeza makadirio' : 'Add estimates'),
                ),
              ),
            ],
          ],
        );
      });
}
