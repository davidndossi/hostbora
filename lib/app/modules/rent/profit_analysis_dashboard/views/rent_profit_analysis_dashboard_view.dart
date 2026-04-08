import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_profit_analysis_dashboard_controller.dart';

class RentProfitAnalysisDashboardView extends BaseView<RentProfitAnalysisDashboardController> {
  RentProfitAnalysisDashboardView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Dashibodi ya Uchambuzi wa Faida' : 'Profit analysis dashboard');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya faida bado.' : 'No profit data available yet.'),
          );
        }
        final margin = d.incomeTotal <= 0 ? 0.0 : (d.netProfit / d.incomeTotal) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Faida' : 'Profit',
              _isSw ? 'Dashibodi ya uchambuzi' : 'Analysis dashboard',
              subtitle: _isSw
                  ? 'Maarifa ya margin na mikakati kutoka takwimu halisi za portfolio.'
                  : 'Margin and strategy insights from real portfolio figures.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Mapato' : 'Income', value: 'TZS ${d.incomeTotal.toStringAsFixed(0)}', icon: Icons.account_balance_outlined, accent: Colors.green),
              rentMetricTile(label: _isSw ? 'Faida halisi' : 'Net profit', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.auto_graph_outlined, accent: Colors.indigo),
              rentMetricTile(label: _isSw ? 'Margin ya faida' : 'Profit margin', value: '${margin.toStringAsFixed(1)}%', icon: Icons.percent_outlined, accent: Colors.brown),
            ]),
            const SizedBox(height: 12),
            rentInsightCard(
              title: _isSw ? 'Dokezo la mtindo wa AI' : 'AI-style insight',
              message: margin < 0
                  ? (_isSw
                      ? 'Portfolio yako kwa sasa iko kwenye margin hasi. Kagua gharama za mara kwa mara na boresha ujazaji.'
                      : 'Your portfolio is currently in negative margin. Review high recurring expenses and optimize occupancy.')
                  : (_isSw
                      ? 'Margin ya sasa ni chanya. Endelea kuboresha upyaishaji na ufanisi wa matengenezo ili kudumisha ukuaji.'
                      : 'Current margin is positive. Keep improving renewals and maintenance efficiency to sustain growth.'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.onApplyStrategy,
              child: Text(_isSw ? 'Tumia mkakati' : 'Apply strategy'),
            ),
          ],
        );
      });
}
