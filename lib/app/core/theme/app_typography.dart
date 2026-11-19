import 'package:flutter/material.dart';

/// One type scale for the whole app, modelled on the Settings screen:
/// light weights (w500/w600), tight negative tracking on large numbers, wide
/// tracking on small uppercase labels, and the platform system font
/// (San Francisco on iOS, Roboto on Android). Never set `fontFamily`.
///
/// Styles carry no color so they inherit the theme's text color in light and
/// dark mode.
///
/// Tabular figures are switched on for every style so digits are equal width
/// and money columns line up. Because [Material] uses `textTheme.bodyMedium`
/// as the default text style, hand-written `TextStyle(...)` widgets under a
/// Scaffold inherit this too.
abstract final class AppTypography {
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Large figures: hero amounts, big stats.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.15,
    letterSpacing: -1.0,
    fontFeatures: tabularFigures,
  );

  /// Screen and section headings, dialog titles.
  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: tabularFigures,
  );

  /// Card titles and emphasised rows.
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    fontFeatures: tabularFigures,
  );

  /// Secondary headings and money inside rows.
  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    fontFeatures: tabularFigures,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: tabularFigures,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    fontFeatures: tabularFigures,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    fontFeatures: tabularFigures,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: tabularFigures,
  );

  static const TextStyle captionStrong = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFeatures: tabularFigures,
  );

  /// Small uppercase labels ("COLLECTED", month names). Smallest allowed size.
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.2,
    fontFeatures: tabularFigures,
  );

  /// Money amounts inside lists and rows.
  static const TextStyle money = subtitle;

  /// Hero / headline money.
  static const TextStyle moneyLarge = display;

  /// Maps the scale onto Material text slots. `labelLarge` is left alone so
  /// buttons keep their existing look.
  static TextTheme textTheme({TextStyle? labelLarge}) {
    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: headline,
      headlineLarge: headline,
      headlineMedium: headline,
      headlineSmall: headline,
      titleLarge: headline,
      // Text fields and list tiles read titleMedium/bodyLarge, so these stay
      // regular weight.
      titleMedium: bodyLarge,
      titleSmall: subtitle,
      bodyLarge: bodyLarge,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: labelLarge,
      labelMedium: captionStrong,
      labelSmall: overline,
    );
  }
}
