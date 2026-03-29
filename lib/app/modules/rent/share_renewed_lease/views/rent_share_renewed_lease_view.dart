import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_share_renewed_lease_controller.dart';

class RentShareRenewedLeaseView extends BaseView<RentShareRenewedLeaseController> {
  RentShareRenewedLeaseView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Share lease');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rentCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Renewed lease summary',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(
                  'Tenant: A. Juma\nProperty: Masaki 2BR\nTerm: Apr 1, 2026 – Mar 31, 2027',
                  style: TextStyle(color: RentTheme.muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          rentPrimaryButton(
            label: 'Share PDF',
            onPressed: () {},
            icon: Icons.share_outlined,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.copy),
            label: const Text('Copy link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RentTheme.teal,
              side: const BorderSide(color: RentTheme.teal),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
