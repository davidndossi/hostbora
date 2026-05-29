import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_others_tab_controller.dart';

/// "Others" tab: shortcuts to additional rent flows (no duplicate bottom nav).
class RentOthersTabView extends RentBaseView<RentOthersTabController> {
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
  //           final bg = isDark ? context.tokens.scaffoldBackground : Colors.white;
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
        _isSw ? 'Kituo cha Msaada' : 'Help center',
        Icons.help_outline_rounded,
        Routes.HELP_CENTER,
      ),
      _OthersLink(
        _isSw ? 'Msimamizi wa AI' : 'AI Manager',
        Icons.auto_awesome_outlined,
        Routes.AI_MANAGER,
      ),
      _OthersLink(
        appLocalization.managePayments,
        Icons.receipt_long_outlined,
        Routes.RENT_MANAGE_PAYMENTS,
      ),
      _OthersLink(_isSw ? 'Kikasha' : 'Inbox', Icons.inbox_outlined, Routes.RENT_CONCIERGE_INBOX),
      _OthersLink(_isSw ? 'Panga Matengenezo' : 'Schedule Maintenance', Icons.engineering_outlined, Routes.RENT_SCHEDULE_MAINTENANCE_FORM),
      _OthersLink(_isSw ? 'Kitovu cha Mikataba' : 'Contract hub', Icons.article_outlined, Routes.RENT_CONTRACT_HUB),
      _OthersLink(
        _isSw ? 'Tuma SMS / WhatsApp' : 'Send SMS / WhatsApp',
        Icons.sms_outlined,
        Routes.SEND_SMS,
        arguments: const {'workspace': 'rent'},
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _othersGridTile(context, items[i]),
    );
  }

  Widget _othersGridTile(BuildContext context, _OthersLink link) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final titleColor = isDark ? tokens.textPrimary : RentTheme.navy;
    final iconColor = isDark ? tokens.accent : RentTheme.teal;
    final cardColor = tokens.cardBackground;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.toNamed(link.route, arguments: link.arguments),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(link.icon, color: iconColor, size: 26),
                const SizedBox(height: 8),
                Text(
                  link.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OthersLink {
  const _OthersLink(this.title, this.icon, this.route, {this.arguments});
  final String title;
  final IconData icon;
  final String route;
  final Map<String, dynamic>? arguments;
}
