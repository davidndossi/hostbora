import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_monthly_pl_summary_controller.dart';

class RentMonthlyPlSummaryView extends BaseView<RentMonthlyPlSummaryController> {
  RentMonthlyPlSummaryView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Monthly P&L summary');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) return const Center(child: Text('No P&L data available yet.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle('P&L', 'Monthly summary', subtitle: 'Live profitability snapshot based on captured transactions.'),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: 'Income', value: 'TZS ${d.incomeTotal.toStringAsFixed(0)}', icon: Icons.trending_up_outlined, accent: Colors.green),
              rentMetricTile(label: 'Expense', value: 'TZS ${d.expenseTotal.toStringAsFixed(0)}', icon: Icons.trending_down_outlined, accent: Colors.redAccent),
              rentMetricTile(label: 'Net', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.savings_outlined, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentCard(child: rentSplitBar(first: d.incomeTotal, second: d.expenseTotal)),
          ],
        );
      });
}
