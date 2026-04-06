import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_profit_analysis_dashboard_controller.dart';

class RentProfitAnalysisDashboardView extends BaseView<RentProfitAnalysisDashboardController> {
  RentProfitAnalysisDashboardView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Profit analysis dashboard');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No profit data available yet.'));
        final margin = d.incomeTotal <= 0 ? 0.0 : (d.netProfit / d.incomeTotal) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('Profit', 'Analysis dashboard', subtitle: 'Margin and strategy insights from real portfolio figures.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Income', value: 'TZS ${d.incomeTotal.toStringAsFixed(0)}', icon: Icons.account_balance_outlined, accent: Colors.green),
              rentMetricTile(label: 'Net profit', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.auto_graph_outlined, accent: Colors.indigo),
              rentMetricTile(label: 'Profit margin', value: '${margin.toStringAsFixed(1)}%', icon: Icons.percent_outlined, accent: Colors.brown),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: 'AI-style insight',
              message: margin < 0
                  ? 'Your portfolio is currently in negative margin. Review high recurring expenses and optimize occupancy.'
                  : 'Current margin is positive. Keep improving renewals and maintenance efficiency to sustain growth.',
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: controller.onApplyStrategy, child: const Text('Apply strategy')),
          ],
        );
      });
}
