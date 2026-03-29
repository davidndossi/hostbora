import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_analysis_controller.dart';

class RentPropertyRoiAnalysisView extends BaseView<RentPropertyRoiAnalysisController> {
  RentPropertyRoiAnalysisView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Property ROI');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash-on-cash ROI (est.)', style: TextStyle(color: RentTheme.muted)),
                const SizedBox(height: 6),
                Text(
                  '11.4%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: RentTheme.teal),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RentTheme.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ROI vs benchmark (mock)',
                    style: TextStyle(color: RentTheme.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          rentSectionLabel('Inputs'),
          rentCard(
            child: const Text(
              'Purchase price, capex, NOI - connect to backend later.',
              style: TextStyle(color: RentTheme.muted),
            ),
          ),
        ],
      ),
    );
  }
}
