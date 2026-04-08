import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_real_dashboard_sections.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_financial_comparison_controller.dart';

class RentFinancialComparisonView extends BaseView<RentFinancialComparisonController> {
  RentFinancialComparisonView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Ulinganisho wa Fedha' : 'Financial comparison');

  @override
  Widget body(BuildContext context) => Obx(() {
        if (controller.loadingRealData.value) return const Center(child: CircularProgressIndicator());
        final d = controller.realData.value;
        if (d == null) {
          return Center(
            child: Text(_isSw ? 'Hakuna data ya fedha bado.' : 'No financial data available yet.'),
          );
        }
        final ratio = d.incomeTotal <= 0 ? 0.0 : (d.expenseTotal / d.incomeTotal) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            rentSectionTitle(
              _isSw ? 'Fedha' : 'Finance',
              _isSw ? 'Bodi ya ulinganisho' : 'Comparison board',
              subtitle: _isSw
                  ? 'Mizani ya mapato na gharama kutoka miamala iliyorekodiwa.'
                  : 'Income and expense balance from recorded transactions.',
            ),
            const SizedBox(height: 12),
            rentMetricGrid([
              rentMetricTile(label: _isSw ? 'Mapato' : 'Income', value: 'TZS ${d.incomeTotal.toStringAsFixed(0)}', icon: Icons.south_west, accent: Colors.green),
              rentMetricTile(label: _isSw ? 'Gharama' : 'Expense', value: 'TZS ${d.expenseTotal.toStringAsFixed(0)}', icon: Icons.north_east, accent: Colors.redAccent),
              rentMetricTile(label: _isSw ? 'Halisi' : 'Net', value: 'TZS ${d.netProfit.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_outlined, accent: Colors.blueGrey),
              rentMetricTile(label: _isSw ? 'Uwiano wa gharama' : 'Expense ratio', value: '${ratio.toStringAsFixed(1)}%', icon: Icons.pie_chart_outline, accent: Colors.brown),
            ]),
            const SizedBox(height: 12),
            rentCard(child: rentSplitBar(first: d.incomeTotal, second: d.expenseTotal)),
          ],
        );
      });
}
