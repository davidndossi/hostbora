import 'package:flutter/material.dart';

/// The app's fixed colour values.
///
/// Theme-aware colours belong in `AppThemeTokens` (`context.tokens`), which
/// resolves per light/dark mode; this class holds only values that are the
/// same in both. Every token here is referenced somewhere — `app_colors_test`
/// fails on a dead one, and on a second token sharing an existing value,
/// because that is how the palette previously grew two brand sets and three
/// different success greens.
abstract class AppColors {
  static const Color designInputBorder = Color(0xFFE0E0E0);
  static const Color designPlaceholder = Color(0xFFA0A0A0);

  static const Color colorWarning = Color(0xFFF5A623);

  static const Color colorAlert = Color(0xFFE74C3C);
  static const Color colorSuccess = Color(0xFF2ECC71);

  static const Color pageBackground = Color(0xFFF6F8F8);
  static const Color appBarIconColor = Color(0xFF000000);
  static const Color appBarTextColor = Color(0xFF000000);

  static const Color centerTextColor = Colors.grey;
  static const MaterialColor colorPrimarySwatch = MaterialColor(0xFF1C6E64, {
    50: Color.fromRGBO(28, 110, 100, .1),
    100: Color.fromRGBO(28, 110, 100, .2),
    200: Color.fromRGBO(28, 110, 100, .3),
    300: Color.fromRGBO(28, 110, 100, .4),
    400: Color.fromRGBO(28, 110, 100, .5),
    500: Color.fromRGBO(28, 110, 100, .6),
    600: Color.fromRGBO(28, 110, 100, .7),
    700: Color.fromRGBO(28, 110, 100, .8),
    800: Color.fromRGBO(28, 110, 100, .9),
    900: Color.fromRGBO(28, 110, 100, 1),
  });
  static const Color colorPrimary = Color(0xFF1C6E64);
  static const Color colorSecondary = Color(0xFF5D9CEC);
  static const Color colorPrimaryLight = Color(0xFFC8E6D5);
  static const Color colorPrimaryDark = Color(0xFF145C54);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFAB0B0B);
  static const Color colorOrange = Color(0xFFff8c42);
  static const Color colorYellow = Color(0xFFfbca07);

  static const Color defaultRippleColor = Color(0x031C6E64);

  static const Color textColorPrimary = Color(0xFF4A4A4A);
  static const Color textColorSecondary = Color(0xFF9FA4B0);
  static const Color textColorGreyLight = Color(0xFFABABAB);
  static const Color textColorGreyDark = Color(0xFF979797);
  static const Color textColorCyan = Color(0xFF38686A);

  static Color elevatedContainerColorOpacity = Colors.grey.withOpacity(0.5);
  static const Color suffixImageColor = Colors.grey;
  static const Color slateBlueGrey = Color(0xFF94A3B8);
}
