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
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    // final leadColor = isDark ? Colors.white : AppColors.appBarIconColor;
    return rentAppBar(
      _isSw ? 'Zaidi' : 'More',
      // leading: IconButton(
      //   icon: Icon(Icons.menu_rounded, color: leadColor),
      //   tooltip: _isSw ? 'Menyu' : 'Menu',
      //   onPressed: () => globalKey.currentState?.openDrawer(),
      // ),
    );
  }

  // @override
  // Widget? drawer() => _buildDrawer();

  // Widget _buildDrawer() {
  //   return Drawer(
  //     child: SafeArea(
  //       child: Builder(
  //         builder: (context) {
  //           final isDark = Theme.of(context).brightness == Brightness.dark;
  //           final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
  //           final items = _drawerLinks(_isSw);
  //           final titleColor = isDark ? Colors.white : RentTheme.navy;
  //           final iconColor = isDark ? const Color(0xFF5EC9C3) : RentTheme.teal;
  //           return ColoredBox(
  //             color: bg,
  //             child: ListView(
  //               padding: EdgeInsets.zero,
  //               children: [
  //                 DrawerHeader(
  //                   margin: EdgeInsets.zero,
  //                   padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
  //                   decoration: const BoxDecoration(
  //                     color: RentTheme.conciergeTeal,
  //                   ),
  //                   child: Align(
  //                     alignment: Alignment.bottomLeft,
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Icon(
  //                           Icons.apartment_rounded,
  //                           color: Colors.white.withValues(alpha: 0.95),
  //                           size: 40,
  //                         ),
  //                         const SizedBox(height: 8),
  //                         Text(
  //                           _isSw ? 'Kodi / Rent' : 'Rent',
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 22,
  //                             fontWeight: FontWeight.w700,
  //                           ),
  //                         ),
  //                         Text(
  //                           _isSw ? 'Menyu ya urambazaji' : 'Navigation menu',
  //                           style: TextStyle(
  //                             color: Colors.white.withValues(alpha: 0.88),
  //                             fontSize: 13,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 ...items.map(
  //                   (e) => ListTile(
  //                     leading: Icon(e.icon, color: iconColor),
  //                     title: Text(
  //                       e.title,
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.w500,
  //                         color: titleColor,
  //                       ),
  //                     ),
  //                     onTap: () {
  //                       Navigator.of(context).pop();
  //                       Get.toNamed(e.route);
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget body(BuildContext context) {
    final items = <_OthersLink>[
      _OthersLink(
        appLocalization.managePayments,
        Icons.receipt_long_outlined,
        Routes.RENT_MANAGE_PAYMENTS,
      ),
      _OthersLink(
        '${appLocalization.reportsHubTitle} (BnB)',
        Icons.insights_outlined,
        Routes.REPORTS_HUB,
      ),
      _OthersLink(_isSw ? 'Kikasha' : 'Inbox', Icons.inbox_outlined, Routes.RENT_CONCIERGE_INBOX),
      _OthersLink(_isSw ? 'Panga Matengenezo' : 'Schedule Maintenance', Icons.engineering_outlined, Routes.RENT_SCHEDULE_MAINTENANCE_FORM),
      _OthersLink(_isSw ? 'Bainisha Tozo za Mpangaji' : 'Define Tenant Charges', Icons.payments_outlined, Routes.RENT_DEFINE_TENANT_CHARGES),
      // _OthersLink(_isSw ? 'Usimamizi wa Wafanyakazi' : 'Staff Management', Icons.badge_outlined, Routes.RENT_STAFF_MANAGEMENT),
      _OthersLink(_isSw ? 'Bainisha Programu ya Uaminifu' : 'Define Loyalty Program', Icons.loyalty_outlined, Routes.RENT_DEFINE_LOYALTY_OFFERS),
      // _OthersLink(_isSw ? 'Ulinganisho wa Fedha' : 'Financial comparison', Icons.compare_arrows_rounded, Routes.RENT_FINANCIAL_COMPARISON),
      // _OthersLink(_isSw ? 'Muhtasari wa Mwezi wa P&L' : 'Monthly P&L summary', Icons.summarize_outlined, Routes.RENT_MONTHLY_PL_SUMMARY),
      _OthersLink(_isSw ? 'Kitovu cha Mikataba' : 'Contract hub', Icons.article_outlined, Routes.RENT_CONTRACT_HUB),
      _OthersLink(_isSw ? 'Mjenzi wa Violezo vya WhatsApp' : 'WhatsApp Template Builder', Icons.chat_outlined, Routes.RENT_WHATSAPP_TEMPLATE_BUILDER),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = items[i];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : RentTheme.navy;
        final trailingColor = isDark ? Colors.white54 : RentTheme.muted;
        final leadingColor = isDark ? const Color(0xFF5EC9C3) : RentTheme.teal;
        return _othersListCard(
          context,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(e.icon, color: leadingColor),
            title: Text(
              e.title,
              style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
            ),
            trailing: Icon(Icons.chevron_right, color: trailingColor),
            onTap: () => Get.toNamed(e.route),
          ),
        );
      },
    );
  }

  /// Same shape as [rentCard], but dark background matches rent shell nav (`0xFF2C2C2E`).
  Widget _othersListCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OthersLink {
  const _OthersLink(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}
