import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_maintenance_cost_analysis_controller.dart';

class RentMaintenanceCostAnalysisView extends BaseView<RentMaintenanceCostAnalysisController> {
  RentMaintenanceCostAnalysisView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Uchambuzi wa Gharama za Matengenezo' : 'Maintenance cost analysis');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna rekodi za matengenezo bado.' : 'No maintenance records available yet.'),
          );
        }
        final avg = d.maintenanceTasks == 0 ? 0.0 : d.expenseTotal / d.maintenanceTasks;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Matengenezo' : 'Maintenance',
              _isSw ? 'Gharama na mzigo wa kazi' : 'Cost and workload',
              subtitle: _isSw
                  ? 'Kazi na mwenendo wa matumizi ya matengenezo kutoka kazi zilizohifadhiwa.'
                  : 'Tasks and maintenance spending trend from saved jobs.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Kazi zilizopangwa' : 'Tasks scheduled', value: '${d.maintenanceTasks}', icon: Icons.build_circle_outlined, accent: Colors.orange),
              rentMetricTile(label: _isSw ? 'Jumla ya gharama' : 'Expenses pool', value: 'TZS ${d.expenseTotal.toStringAsFixed(0)}', icon: Icons.payments_outlined, accent: Colors.redAccent),
              rentMetricTile(label: _isSw ? 'Wastani/kazi (kiashiria)' : 'Avg/task (proxy)', value: 'TZS ${avg.toStringAsFixed(0)}', icon: Icons.calculate_outlined, accent: Colors.brown),
            ]),
          ],
        );
      });
}
