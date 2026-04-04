import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_others_tab_controller.dart';

/// "Others" tab: shortcuts to additional rent flows (no duplicate bottom nav).
class RentOthersTabView extends BaseView<RentOthersTabController> {
  RentOthersTabView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('More');

  @override
  Widget body(BuildContext context) {
    final items = <_OthersLink>[
      _OthersLink('Concierge Inbox', Icons.inbox_outlined, Routes.RENT_CONCIERGE_INBOX),
      _OthersLink('Schedule Maintenance', Icons.engineering_outlined, Routes.RENT_SCHEDULE_MAINTENANCE_FORM),
      _OthersLink('Define Tenant Charges', Icons.payments_outlined, Routes.RENT_DEFINE_TENANT_CHARGES),
      _OthersLink('Staff Management', Icons.badge_outlined, Routes.RENT_STAFF_MANAGEMENT),
      _OthersLink('Define Loyalty Program', Icons.loyalty_outlined, Routes.RENT_DEFINE_LOYALTY_OFFERS),
      _OthersLink('Financial comparison', Icons.compare_arrows_rounded, Routes.RENT_FINANCIAL_COMPARISON),
      _OthersLink('Monthly P&L summary', Icons.summarize_outlined, Routes.RENT_MONTHLY_PL_SUMMARY),
      _OthersLink('Contract hub', Icons.article_outlined, Routes.RENT_CONTRACT_HUB),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = items[i];
        return rentCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(e.icon, color: RentTheme.teal),
            title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, color: RentTheme.navy)),
            trailing: const Icon(Icons.chevron_right, color: RentTheme.muted),
            onTap: () => Get.toNamed(e.route),
          ),
        );
      },
    );
  }
}

class _OthersLink {
  const _OthersLink(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}
