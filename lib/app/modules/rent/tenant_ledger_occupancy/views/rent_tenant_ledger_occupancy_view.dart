import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_tenant_ledger_occupancy_controller.dart';

class RentTenantLedgerOccupancyView extends BaseView<RentTenantLedgerOccupancyController> {
  RentTenantLedgerOccupancyView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Ledger & occupancy');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rentCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Occupancy', style: TextStyle(color: RentTheme.muted)),
                    SizedBox(height: 4),
                    Text(
                      '94%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: RentTheme.teal,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RentTheme.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '6 / 8\nunits let',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          rentSectionLabel('Ledger'),
          rentCard(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Type'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Amt'),
                    ),
                  ],
                ),
                _lr('Mar 1', 'Rent', '2.1M'),
                _lr('Feb 28', 'Water', '50k'),
                _lr('Feb 15', 'Late fee', '10k'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _lr(String a, String b, String c) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(a, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(b, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            c,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
