import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_active_loyalty_programs_controller.dart';

class RentActiveLoyaltyProgramsView extends BaseView<RentActiveLoyaltyProgramsController> {
  RentActiveLoyaltyProgramsView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Active loyalty');

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        rentCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stars_rounded, color: RentTheme.teal),
            title: const Text('Long-stay bonus', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text(
              '12+ months → 1 month free utilities',
              style: TextStyle(color: RentTheme.muted),
            ),
            trailing: Chip(
              label: const Text('Live'),
              backgroundColor: RentTheme.teal.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        rentCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.stars_rounded, color: Colors.grey.shade400),
            title: Text(
              'Referral credit',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600),
            ),
            subtitle: const Text('Paused', style: TextStyle(color: RentTheme.muted)),
          ),
        ),
      ],
    );
  }
}
