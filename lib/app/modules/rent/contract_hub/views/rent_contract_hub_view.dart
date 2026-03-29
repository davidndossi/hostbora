import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_contract_hub_controller.dart';

class RentContractHubView extends BaseView<RentContractHubController> {
  RentContractHubView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Contract hub');

  @override
  Widget body(BuildContext context) {
    final items = [
      'Lease - Masaki 2BR',
      'Addendum - rent review',
      'Termination notice - archive',
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        return rentCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.article_outlined, color: RentTheme.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  items[i],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: RentTheme.muted),
            ],
          ),
        );
      },
    );
  }
}
