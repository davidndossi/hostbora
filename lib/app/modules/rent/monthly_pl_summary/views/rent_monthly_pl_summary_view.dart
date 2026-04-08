import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_monthly_pl_summary_controller.dart';

class RentMonthlyPlSummaryView extends BaseView<RentMonthlyPlSummaryController> {
  RentMonthlyPlSummaryView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Muhtasari wa Mwezi wa P&L' : 'Monthly P&L summary');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya P&L bado.' : 'No P&L data available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'P&L' : 'P&L',
              _isSw ? 'Muhtasari wa mwezi' : 'Monthly summary',
              subtitle: _isSw
                  ? 'Muhtasari hai wa faida kulingana na miamala iliyonaswa.'
                  : 'Live profitability snapshot based on captured transactions.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Mapato' : 'Income', value: 'TZS ${d.incomeTotal.toStringAsFixed(0)}', icon: Icons.trending_up_outlined, accent: Colors.green),
              rentMetricTile(label: _isSw ? 'Gharama' : 'Expense', value: 'TZS ${d.expenseTotal.toStringAsFixed(0)}', icon: Icons.trending_down_outlined, accent: Colors.redAccent),
              rentMetricTile(label: _isSw ? 'Halisi' : 'Net', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.savings_outlined, accent: Colors.indigo),
            ]),
            const SizedBox(height: 12),
            rentCard(child: rentSplitBar(first: d.incomeTotal, second: d.expenseTotal)),
          ],
        );
      });
}
