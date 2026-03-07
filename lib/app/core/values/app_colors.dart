import 'package:flutter/material.dart';

abstract class AppColors {
  // ----- Figma / Create Host Account design (app colors) -----
  static const Color designBackgroundDark = Color(0xFF202020);
  static const Color designSurface = Color(0xFFF6F8F8);
  static const Color designAccent = Color(0xFF1C6E64);
  static const Color designSecondaryText = Color(0xFF4A4A4A);
  static const Color designInputBorder = Color(0xFFE0E0E0);
  static const Color designPlaceholder = Color(0xFFA0A0A0);
  static const Color designAccentDark = Color(0xFF145C54);

  static const Color paaYanguVibrant = Color(0xFF2E8B57);
  static const Color paaYanguWarm = Color(0xFFF5A623);
  static const Color paaYanguDeep = Color(0xFF6B4226);

  static const Color paaYanguChatBlue = Color(0xFF5D9CEC);      // Friendly chat bubbles
  static const Color paaYanguAlert = Color(0xFFE74C3C);        // Notifications
  static const Color paaYanguSuccess = Color(0xFF2ECC71);      // Confirmations

  static const Color paaYanguCream = Color(0xFFF8F1E5);        // Background
  static const Color paaYanguCharcoal = Color(0xFF34495E);     // Text

  static const Color pageBackground = designSurface;
  static const Color statusBarColor = designAccent;
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
  static const Color colorPrimary = designAccent;
  static const Color colorSecondary = Color(0xFF5D9CEC);
  static const Color colorAccent = designAccent;
  static const Color colorLight = Color(0xFFA7FFC8);
  static const Color colorPrimaryLight = Color(0xFFC8E6D5);
  static const Color colorAccentLight = Color(0xFFDAFFE8);
  static const Color colorPrimaryVariant = designAccentDark;
  static const Color colorPrimaryDark = designAccentDark;
  static const Color colorLightGreen = Color(0xFF00EFA7);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color lightGreyColor = designInputBorder;
  static const Color errorColor = Color(0xFFAB0B0B);
  static const Color colorDark = designSecondaryText;
  static const Color colorSuccessGreen = Color(0xFF8ed16f);
  static const Color colorOrange = Color(0xFFff8c42);
  static const Color colorYellow = Color(0xFFfbca07);

  static const Color buttonBgColor = colorPrimary;
  static const Color disabledButtonBgColor = Color(0xFFBFBFC0);
  static const Color defaultRippleColor = Color(0x031C6E64);

  static const Color textColorPrimary = designSecondaryText;
  static const Color textColorSecondary = Color(0xFF9FA4B0);
  static const Color textColorTag = colorPrimary;
  static const Color textColorGreyLight = Color(0xFFABABAB);
  static const Color textColorGreyDark = Color(0xFF979797);
  static const Color textColorBlueGreyDark = Color(0xFF939699);
  static const Color textColorCyan = Color(0xFF38686A);
  static const Color textColorWhite = Color(0xFFFFFFFF);
  static Color searchFieldTextColor = const Color(0xFF323232).withOpacity(0.5);

  static const Color iconColorDefault = Color(0xFFA3A0A0);

  static Color barrierColor = const Color(0xFF000000).withOpacity(0.5);

  static Color timelineDividerColor = const Color(0x5438686A);

  static const Color gradientStartColor = Colors.black87;
  static const Color gradientEndColor = Colors.transparent;
  static const Color silverAppBarOverlayColor = Color(0x80323232);

  static const Color switchActiveColor = colorPrimary;
  static const Color switchInactiveColor = Color(0xFFABABAB);
  static Color elevatedContainerColorOpacity = Colors.grey.withOpacity(0.5);
  static const Color suffixImageColor = Colors.grey;
  static const Color incrementColor = Color(0xFF4F9636);
  static const Color decrementColor = Color(0xFFCF3436);
  static const Color slateBlueGrey = Color(0xFF94A3B8);
}
