import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_profit_analysis_dashboard_controller.dart';

class RentProfitAnalysisDashboardView extends BaseView<RentProfitAnalysisDashboardController> {
  RentProfitAnalysisDashboardView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Profit analysis');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net operating income',
                  style: TextStyle(color: RentTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'TZS 12.4M',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: RentTheme.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: RentTheme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Trend chart (mock)',
                      style: TextStyle(color: RentTheme.muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          rentSectionLabel('Breakdown'),
          rentCard(
            child: Column(
              children: [
                _kv('Gross rent', 'TZS 18.2M'),
                const Divider(),
                _kv('Operating expenses', '-TZS 4.1M', valueColor: RentTheme.warnFg),
                const Divider(),
                _kv('Maintenance', '-TZS 1.7M', valueColor: RentTheme.warnFg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: RentTheme.muted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? RentTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
