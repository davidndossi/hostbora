import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/app/core/theme/theme_controller.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/app_bar_title.dart';

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
  });

  @override
  Size get preferredSize => bottom == null ? AppBar().preferredSize : Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isLight
        ? Colors.white
        : (isDark ? Colors.white : AppColors.appBarIconColor);
    final currentLang = Get.locale?.languageCode == 'sw' ? 'sw' : 'en';
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
            final nextLocale = nextLang == 'sw'
                ? const Locale('sw', 'TZ')
                : const Locale('en', 'US');
            Get.updateLocale(nextLocale);
            try {
              final pref = Get.find<PreferenceManager>(
                tag: (PreferenceManager).toString(),
              );
              await pref.setString(PreferenceManager.keyLang, nextLang);
            } catch (_) {
              // No-op: locale is already updated for current session.
            }
          },
        ),
    ];

    return AppBar(
      backgroundColor: Colors.transparent,
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
}
