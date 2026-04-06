import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_maintenance_cost_analysis_controller.dart';

class RentMaintenanceCostAnalysisView extends BaseView<RentMaintenanceCostAnalysisController> {
  RentMaintenanceCostAnalysisView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Maintenance cost analysis');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No maintenance records available yet.'));
        final avg = d.maintenanceTasks == 0 ? 0.0 : d.expenseTotal / d.maintenanceTasks;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Maintenance', 'Cost and workload', subtitle: 'Tasks and maintenance spending trend from saved jobs.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Tasks scheduled', value: '${d.maintenanceTasks}', icon: Icons.build_circle_outlined, accent: Colors.orange),
              rentMetricTile(label: 'Expenses pool', value: 'TZS ${d.expenseTotal.toStringAsFixed(0)}', icon: Icons.payments_outlined, accent: Colors.redAccent),
              rentMetricTile(label: 'Avg/task (proxy)', value: 'TZS ${avg.toStringAsFixed(0)}', icon: Icons.calculate_outlined, accent: Colors.brown),
            ]),
          ],
        );
      });
}
