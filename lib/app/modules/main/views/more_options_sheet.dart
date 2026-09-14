import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../routes/app_pages.dart';
import '../controllers/bottom_nav_controller.dart';
import '../controllers/main_controller.dart';

/// Figma "Find More Options" sheet (More v2 / node 620:5579).
class MoreOptionsSheet extends StatelessWidget {
  const MoreOptionsSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  bool get _isSw => Get.locale?.languageCode == 'sw';
  String _t(String en, String sw) => _isSw ? sw : en;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1F2A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final items = _items(AppLocalizations.of(context)!);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
              child: Text(
                _t('More Options', 'Chaguo Zaidi'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                  height: 1,
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.withValues(alpha: 0.35),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.48,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 56),
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 18,
                  endIndent: 18,
                  color: Colors.grey.withValues(alpha: 0.25),
                ),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return InkWell(
                    onTap: () => _onTap(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 16, color: const Color(0xFF1F1F1F)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                color: titleColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(_MoreOption item) async {
    onClose();
    if (item.route == null) return;
    if (item.useMainAction) {
      final main = Get.find<MainController>();
      switch (item.route) {
        case Routes.ADD_LISTING:
          await main.addProperty();
          return;
        default:
          break;
      }
    }
    await Get.toNamed(item.route!);
  }

  List<_MoreOption> _items(AppLocalizations appLocalization) {
    return [
      _MoreOption(
        label: _t('Add Property', 'Ongeza Mali'),
        icon: Icons.add_home_work_outlined,
        iconBg: const Color(0xFFEEE298),
        route: Routes.ADD_LISTING,
        useMainAction: true,
      ),
      _MoreOption(
        label: _t('Add Income', 'Ongeza Mapato'),
        icon: Icons.attach_money_rounded,
        iconBg: const Color(0xFFB8F1D7),
        route: Routes.RECORD_PAYMENT,
      ),
      _MoreOption(
        label: _t('Add Expenses', 'Ongeza Matumizi'),
        icon: Icons.trending_up_rounded,
        iconBg: const Color(0xFFF5CABC),
        route: Routes.ADD_EXPENSE,
      ),
      _MoreOption(
        label: _t('Help Center', 'Kituo cha Msaada'),
        icon: Icons.help_outline_rounded,
        iconBg: const Color(0xFFBCE784),
        route: Routes.HELP_CENTER,
      ),
      _MoreOption(
        label: _t('Reports', 'Ripoti'),
        icon: Icons.receipt_long_outlined,
        iconBg: const Color(0xFFDCB5F3),
        route: Routes.REPORTS_HUB,
      ),
      _MoreOption(
        label: _t('Contract Hub', 'Kitovu cha Mikataba'),
        icon: Icons.contact_page_outlined,
        iconBg: const Color(0xFFEEE298),
        route: Routes.RENT_CONTRACT_HUB,
      ),
      _MoreOption(
        label: _t('Host Calendar', 'Kalenda'),
        icon: Icons.calendar_month_outlined,
        iconBg: const Color(0xFFF5CABC),
        route: Routes.HOST_CALENDAR,
      ),
      _MoreOption(
        label: _t('Guest Access', 'Ufikiaji wa wageni'),
        icon: Icons.key_outlined,
        iconBg: const Color(0xFFB8F1D7),
        route: Routes.GUEST_ACCESS_CODES,
      ),
      _MoreOption(
        label: _t('Documents', 'Nyaraka'),
        icon: Icons.folder_open_outlined,
        iconBg: const Color(0xFFDCB5F3),
        route: Routes.PROPERTY_VAULT,
      ),
      _MoreOption(
        label: _t('Offers', 'Ofa'),
        icon: Icons.stars_rounded,
        iconBg: const Color(0xFFEEE298),
        route: Routes.RENT_ACTIVE_LOYALTY_PROGRAMS,
      ),
      _MoreOption(
        label: _t('Guest history', 'Historia ya Wageni'),
        icon: Icons.people_outline_rounded,
        iconBg: const Color(0xFFB8F1D7),
        route: Routes.GUEST_HISTORY,
      ),
      _MoreOption(
        label: appLocalization.sendFeedback,
        icon: Icons.feedback_outlined,
        iconBg: const Color(0xFFF5CABC),
        route: Routes.FEEDBACK,
      ),
      _MoreOption(
        label: appLocalization.support,
        icon: Icons.help_outline,
        iconBg: const Color(0xFFBCE784),
        route: Routes.SUPPORT,
      ),
    ];
  }
}

class _MoreOption {
  const _MoreOption({
    required this.label,
    required this.icon,
    required this.iconBg,
    this.route,
    this.useMainAction = false,
  });

  final String label;
  final IconData icon;
  final Color iconBg;
  final String? route;
  final bool useMainAction;
}

/// Full-screen scrim + sheet layered above page content (nav stays visible).
class MoreOptionsOverlay extends StatelessWidget {
  const MoreOptionsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<BottomNavController>();
    return Obx(() {
      if (!nav.moreMenuOpen.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: Stack(
          children: [
            GestureDetector(
              onTap: nav.closeMoreMenu,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F).withValues(alpha: 0.30),
                  backgroundBlendMode: BlendMode.srcOver,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    stops: const [0.45, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 78 + MediaQuery.paddingOf(context).bottom,
              child: MoreOptionsSheet(onClose: nav.closeMoreMenu),
            ),
          ],
        ),
      );
    });
  }
}
