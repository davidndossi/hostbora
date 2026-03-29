import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_monthly_pl_summary_controller.dart';

class RentMonthlyPlSummaryView extends BaseView<RentMonthlyPlSummaryController> {
  RentMonthlyPlSummaryView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Monthly P&L');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: rentCard(
        child: Column(
          children: [
            _plRow('Rental income', 'TZS 8,200,000'),
            _plRow('Other income', 'TZS 120,000'),
            const Divider(height: 24),
            _plRow('Total income', 'TZS 8,320,000', bold: true),
            const SizedBox(height: 12),
            _plRow('Payroll & staffing', '-TZS 1,100,000', neg: true),
            _plRow('Maintenance', '-TZS 640,000', neg: true),
            _plRow('Utilities & fees', '-TZS 210,000', neg: true),
            const Divider(height: 24),
            _plRow('Net profit', 'TZS 6,370,000', bold: true, accent: true),
          ],
        ),
      ),
    );
  }

  Widget _plRow(String a, String b, {bool bold = false, bool neg = false, bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            a,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: RentTheme.navy,
            ),
          ),
          Text(
            b,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent ? RentTheme.teal : (neg ? RentTheme.warnFg : RentTheme.navy),
            ),
          ),
        ],
      ),
    );
  }
}
