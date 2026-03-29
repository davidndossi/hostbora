import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_loyalty_offers_controller.dart';

class RentDefineLoyaltyOffersView extends BaseView<RentDefineLoyaltyOffersController> {
  RentDefineLoyaltyOffersView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Loyalty offers');

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
                  'Early payment discount',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  '5% off if paid 5+ days before due date.',
                  style: TextStyle(color: RentTheme.muted),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: true,
                  activeThumbColor: RentTheme.teal,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          rentTextField(
            label: 'Reward points per TZS 100k rent',
            hint: 'e.g. 50',
          ),
          rentPrimaryButton(
            label: 'Save offers',
            onPressed: () {},
            icon: Icons.card_giftcard_outlined,
          ),
        ],
      ),
    );
  }
}
