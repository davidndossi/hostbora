import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_financial_comparison_controller.dart';

class RentFinancialComparisonView extends BaseView<RentFinancialComparisonController> {
  RentFinancialComparisonView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Financial comparison');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: rentCard(
        child: Table(
          border: TableBorder.all(
            color: RentTheme.border,
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Metric', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('This year'),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Last year'),
                ),
              ],
            ),
            _tr('NOI', '12.4M', '11.1M'),
            _tr('Opex ratio', '32%', '34%'),
            _tr('Vacancy', '4%', '7%'),
          ],
        ),
      ),
    );
  }

  TableRow _tr(String a, String b, String c) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(a)),
        Padding(padding: const EdgeInsets.all(8), child: Text(b)),
        Padding(padding: const EdgeInsets.all(8), child: Text(c)),
      ],
    );
  }
}
