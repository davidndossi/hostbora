import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/app/data/local/preference/preference_manager.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/app_bar_title.dart';

//Default appbar customized with the design of our app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appBarTitleText;
  final List<Widget>? actions;
  final bool isBackButtonEnabled;
  final bool isCentered;
  final bool isLight;
  final PreferredSizeWidget? bottom;
  final bool showLanguageToggle;

  const CustomAppBar({
    super.key,
    required this.appBarTitleText,
    this.actions,
    this.isBackButtonEnabled = true,
    this.isCentered = false,
    this.isLight = false,
    this.bottom,
    this.showLanguageToggle = true,
  });

  @override
  Size get preferredSize => bottom == null ? AppBar().preferredSize : Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final currentLang = Get.locale?.languageCode == 'sw' ? 'sw' : 'en';
    final actionsList = <Widget>[
      ...?actions,
      if (showLanguageToggle)
        IconButton(
          tooltip: currentLang == 'sw' ? 'Badili lugha' : 'Change language',
          icon: const Icon(Icons.language),
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
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      centerTitle: isCentered,
      elevation: 0,
      automaticallyImplyLeading: isBackButtonEnabled,
      actions: actionsList,
      iconTheme: IconThemeData(color: isLight ? Colors.white : AppColors.appBarIconColor),
      title: AppBarTitle(text: appBarTitleText),
      bottom: bottom
    );
  }
}
