import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '/app/core/locale/app_locale_controller.dart';
import '/app/core/theme/theme_controller.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/service/session_service.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/app_bar_title.dart';
import '/app/core/widget/base_currency_dialog.dart';

//Default appbar customized with the design of our app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appBarTitleText;
  final List<Widget>? actions;
  /// When set, replaces the default back leading control ([automaticallyImplyLeading] becomes false).
  final Widget? leading;
  final bool isBackButtonEnabled;
  final bool isCentered;
  final bool isLight;
  final PreferredSizeWidget? bottom;
  final bool showLanguageToggle;
  final bool showThemeToggle;
  /// When null, the bar stays transparent (default). Pass a solid color on
  /// scroll-heavy screens so list outlines do not show through title/actions.
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.appBarTitleText,
    this.actions,
    this.leading,
    this.isBackButtonEnabled = true,
    this.isCentered = false,
    this.isLight = false,
    this.bottom,
    this.showLanguageToggle = true,
    this.showThemeToggle = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => bottom == null ? AppBar().preferredSize : Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isLight
        ? Colors.white
        : (isDark ? Colors.white : AppColors.appBarIconColor);
    final currentLang = Get.isRegistered<AppLocaleController>()
        ? (Get.find<AppLocaleController>().isSw ? 'sw' : 'en')
        : (Get.locale?.languageCode == 'sw' ? 'sw' : 'en');
    final themeController =
        Get.isRegistered<ThemeController>() ? Get.find<ThemeController>() : null;
    final actionsList = <Widget>[
      ...?actions,
      if (showThemeToggle && themeController != null)
        Obx(
          () => IconButton(
            tooltip: themeController.isDarkMode.value
                ? (currentLang == 'sw' ? 'Tumia mandhari ya mwanga' : 'Use light theme')
                : (currentLang == 'sw' ? 'Tumia mandhari ya giza' : 'Use dark theme'),
            icon: Icon(
              themeController.isDarkMode.value
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: actionColor,
            ),
            onPressed: themeController.toggleTheme,
          ),
        ),
      if (showLanguageToggle)
        IconButton(
          tooltip: currentLang == 'sw' ? 'Badili lugha' : 'Change language',
          icon: Icon(Icons.language, color: actionColor),
          onPressed: () async {
            final nextLang = currentLang == 'sw' ? 'en' : 'sw';
            if (Get.isRegistered<AppLocaleController>()) {
              await Get.find<AppLocaleController>().setLanguage(nextLang);
            } else {
              final nextLocale = nextLang == 'sw'
                  ? const Locale('sw', 'TZ')
                  : const Locale('en', 'US');
              Get.updateLocale(nextLocale);
              try {
                final pref = Get.find<PreferenceManager>(
                  tag: (PreferenceManager).toString(),
                );
                await pref.setString(PreferenceManager.keyLang, nextLang);
              } catch (_) {}
            }
          },
        ),
      _AuthenticatedOnly(
        child: IconButton(
          tooltip: currentLang == 'sw' ? 'Zaidi' : 'More',
          icon: Icon(Icons.more_vert, color: actionColor),
          onPressed: () => _showAppBarMenu(context, currentLang),
        ),
      ),
    ];

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      forceMaterialTransparency: backgroundColor == null,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeController!.isDarkMode.value ? Brightness.light : Brightness.dark,
        statusBarBrightness: themeController.isDarkMode.value ? Brightness.dark : Brightness.light,
      ),
      centerTitle: isCentered,
      elevation: 0,
      leading: leading,
      automaticallyImplyLeading: leading == null && isBackButtonEnabled,
      actions: actionsList,
      iconTheme: IconThemeData(color: actionColor),
      actionsIconTheme: IconThemeData(color: actionColor),
      title: AppBarTitle(text: appBarTitleText),
      bottom: bottom
    );
  }

  void _showAppBarMenu(BuildContext context, String currentLang) {
    final isSw = currentLang == 'sw';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.currency_exchange_rounded),
              title: Text(isSw ? 'Badilisha sarafu ya msingi' : 'Change base currency'),
              subtitle: Text(
                isSw
                    ? 'Chagua sarafu ya ripoti na dashibodi'
                    : 'Choose currency for reports and dashboards',
              ),
              onTap: () {
                Navigator.pop(ctx);
                showBaseCurrencyDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(isSw ? 'Kikasha' : 'Inbox'),
              subtitle: Text(
                isSw ? 'Taarifa na ujumbe' : 'Notifications and messages',
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(Routes.RENT_CONCIERGE_INBOX);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(isSw ? 'Kituo cha msaada' : 'Help center'),
              subtitle: Text(
                isSw
                    ? 'Maswali yanayoulizwa sana na mwongozo'
                    : 'FAQs and how-to guides',
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(Routes.HELP_CENTER);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(isSw ? 'Mipangilio' : 'Settings'),
              subtitle: Text(
                isSw
                    ? 'Akaunti, PIN, na mapendeleo'
                    : 'Account, PIN, and preferences',
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(Routes.SETTINGS);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Sign-in / PIN-setup routes where session tokens may already exist (e.g. after
/// OTP) but the user is not yet in the main app — hide account More actions.
const _kPreAppRoutes = <String>{
  Routes.SPLASH,
  Routes.ONBOARDING,
  Routes.AUTH,
  Routes.OTP,
  Routes.CREATE_HOST_ACCOUNT,
  Routes.WELCOME_BACK,
  Routes.CHANGE_PIN,
  Routes.RESET_PASSWORD,
  Routes.VERIFY_IDENTITY,
};

/// Shows [child] only when a local auth session exists and the user is past
/// sign-in / PIN setup (not merely holding post-OTP tokens).
class _AuthenticatedOnly extends StatefulWidget {
  const _AuthenticatedOnly({required this.child});

  final Widget child;

  @override
  State<_AuthenticatedOnly> createState() => _AuthenticatedOnlyState();
}

class _AuthenticatedOnlyState extends State<_AuthenticatedOnly> {
  late final Future<bool> _authenticated;

  @override
  void initState() {
    super.initState();
    _authenticated = _resolveAuthenticated();
  }

  Future<bool> _resolveAuthenticated() async {
    try {
      if (_kPreAppRoutes.contains(Get.currentRoute)) {
        return false;
      }
      if (!Get.isRegistered<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      )) {
        return false;
      }
      final pref = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      return SessionService.hasLocalSession(pref);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authenticated,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return widget.child;
      },
    );
  }
}
