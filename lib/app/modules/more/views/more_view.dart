import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/more_controller.dart';

/// Main-shell "More" tab — shortcuts to secondary flows (settings, AI, reports, etc.).
class MoreView extends BaseView<MoreController> {
  MoreView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t(String en, String sw) => _isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.more,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _links();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _gridTile(
        context,
        link: items[i],
        tokens: tokens,
        isDark: isDark,
      ),
    );
  }

  List<_MoreLink> _links() {
    return [
      _MoreLink(
        _t('Help center', 'Kituo cha Msaada'),
        Icons.help_outline_rounded,
        Routes.HELP_CENTER,
      ),
      // _MoreLink(
      //   _t('AI Manager', 'Msimamizi wa AI'),
      //   Icons.auto_awesome_outlined,
      //   Routes.AI_MANAGER,
      // ),
      _MoreLink(
        _t('Reports', 'Ripoti'),
        Icons.assessment_outlined,
        Routes.REPORTS_HUB,
      ),
      // _OthersLink(_isSw ? 'Kikasha' : 'Inbox', Icons.inbox_outlined, Routes.RENT_CONCIERGE_INBOX),
      _MoreLink(
        _t('Contract hub', 'Kitovu cha Mikataba'),
        Icons.article_outlined,
        Routes.RENT_CONTRACT_HUB
      ),
      _MoreLink(
        _t('Host calendar', 'Kalenda'),
        Icons.calendar_month_outlined,
        Routes.HOST_CALENDAR,
      ),
      _MoreLink(
        _t('Guest access', 'Ufikiaji wa wageni'),
        Icons.key_outlined,
        Routes.GUEST_ACCESS_CODES,
      ),
      _MoreLink(
        _t('Send SMS / WhatsApp', 'Tuma SMS / WhatsApp'),
        Icons.sms_outlined,
        Routes.SEND_SMS,
        arguments: const {'workspace': 'bnb'},
      ),
      _MoreLink(
        _t('Documents', 'Nyaraka'),
        Icons.folder_outlined,
        Routes.PROPERTY_VAULT,
      ),
      _MoreLink(
        _t('Guest history', 'Historia ya Wageni'),
        Icons.people_outline_rounded,
        Routes.GUEST_HISTORY,
      ),
      _MoreLink(
        _t('Design studio', 'Studio ya ubunifu'),
        Icons.palette_outlined,
        Routes.INTERIOR_DESIGN_STUDIO,
      ),
      _MoreLink(
        _t('Settings', 'Mipangilio'),
        Icons.settings_outlined,
        Routes.SETTINGS,
      ),
    ];
  }

  Widget _gridTile(
    BuildContext context, {
    required _MoreLink link,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final titleColor = tokens.textPrimary;
    final iconColor = isDark ? tokens.accent : AppColors.colorPrimary;
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

class _MoreLink {
  const _MoreLink(
    this.title,
    this.icon,
    this.route, {
    this.arguments,
  });

  final String title;
  final IconData icon;
  final String route;
  final Map<String, dynamic>? arguments;
}
