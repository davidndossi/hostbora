import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_share_renewed_lease_controller.dart';

class RentShareRenewedLeaseView extends BaseView<RentShareRenewedLeaseController> {
  RentShareRenewedLeaseView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(_isSw ? 'Shiriki Mkataba' : 'Share lease');

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
                Text(_isSw ? 'Muhtasari wa mkataba ulioboreshwa' : 'Renewed lease summary',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(
                  _isSw
                      ? 'Mpangaji: A. Juma\nMali: Masaki 2BR\nMuda: Apr 1, 2026 – Mar 31, 2027'
                      : 'Tenant: A. Juma\nProperty: Masaki 2BR\nTerm: Apr 1, 2026 – Mar 31, 2027',
                  style: TextStyle(color: RentTheme.muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          rentPrimaryButton(
            label: _isSw ? 'Shiriki PDF' : 'Share PDF',
            onPressed: () {},
            icon: Icons.share_outlined,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.copy),
            label: Text(_isSw ? 'Nakili kiungo' : 'Copy link'),
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
