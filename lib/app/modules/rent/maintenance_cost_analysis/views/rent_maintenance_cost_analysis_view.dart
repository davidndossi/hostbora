import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_maintenance_cost_analysis_controller.dart';

class RentMaintenanceCostAnalysisView extends BaseView<RentMaintenanceCostAnalysisController> {
  RentMaintenanceCostAnalysisView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Maintenance costs');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          rentCard(
            child: Column(
              children: [
                _bar('Plumbing', 0.35),
                const SizedBox(height: 10),
                _bar('Electrical', 0.22),
                const SizedBox(height: 10),
                _bar('HVAC', 0.18),
                const SizedBox(height: 10),
                _bar('Other', 0.25),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Total tracked: TZS 4.2M (YTD)',
            style: TextStyle(color: RentTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(pct * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: RentTheme.border,
            color: RentTheme.teal,
          ),
        ),
      ],
    );
  }
}
