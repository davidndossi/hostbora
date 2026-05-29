import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

/// Semantic colors for long forms — pass into helpers instead of raw [isDark] hex.
class FormSurfaceColors {
  FormSurfaceColors._(this.context)
      : tokens = context.tokens,
        isDark = Theme.of(context).brightness == Brightness.dark;

  factory FormSurfaceColors.of(BuildContext context) =>
      FormSurfaceColors._(context);

  final BuildContext context;
  final AppThemeTokens tokens;
  final bool isDark;

  Color get scaffold => tokens.scaffoldBackground;

  Color get card => tokens.cardBackground;

  Color get fill => tokens.elevatedSurface;

  Color get border => tokens.border;

  Color get headline => tokens.textPrimary;

  Color get hint => tokens.textMuted;

  Color get secondary => tokens.textSecondary;

  Color get divider => isDark ? tokens.elevatedSurface : const Color(0xFFEDEDED);

  Color get tileBg => isDark ? tokens.scaffoldBackground : const Color(0xFFF8F8F8);

  Color get inputFill => isDark ? tokens.elevatedSurface : Colors.white;

  Color get inputBorder =>
      isDark ? Colors.white.withValues(alpha: 0.18) : tokens.border;

  Color get dropdownBg => tokens.cardBackground;

  /// Caps / field labels above inputs.
  Color get sectionLabel => hint;

  /// Amount, date, and notes wells on payment/expense forms.
  Color get fieldWellFill => isDark ? fill : Colors.transparent;

  /// Unselected category/expense chips.
  Color get chipUnselectedBg => isDark ? fill : const Color(0xFFF1F1EE);

  /// “Impact on performance” and similar info banners.
  Color get impactBannerBg => isDark ? card : const Color(0xFFF4F3EF);
}
