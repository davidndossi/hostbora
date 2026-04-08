import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_contract_hub_controller.dart';

class RentContractHubView extends BaseView<RentContractHubController> {
  RentContractHubView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(_isSw ? 'Kitovu cha Mikataba' : 'Contract hub');

  @override
  Widget body(BuildContext context) {
    final items = [
      _isSw ? 'Mkataba - Masaki 2BR' : 'Lease - Masaki 2BR',
      _isSw ? 'Nyongeza - mapitio ya kodi' : 'Addendum - rent review',
      _isSw ? 'Notisi ya kusitisha - kumbukumbu' : 'Termination notice - archive',
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
