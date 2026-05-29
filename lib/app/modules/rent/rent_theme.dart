import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

/// Rent product line — brand accents + theme-aware surfaces via [AppThemeTokens].
abstract class RentTheme {
  static const Color conciergeTeal = Color(0xFF0D5C5A);
  static const Color teal = Color(0xFF149C95);
  static const Color navy = Color(0xFF1B2838);
  static const Color warnBg = Color(0xFFFFF4ED);
  static const Color warnFg = Color(0xFFC45C2A);

  /// Light-mode canvas (use [canvasBg] in widgets).
  static const Color canvas = Color(0xFFF9F8F4);
  static const Color sectionMist = Color(0xFFEBE9E4);

  static Color canvasBg(BuildContext context) => context.tokens.scaffoldBackground;

  static Color cardBg(BuildContext context) => context.tokens.cardBackground;

  static Color elevatedBg(BuildContext context) => context.tokens.elevatedSurface;

  static Color primaryText(BuildContext context) => context.tokens.textPrimary;

  static Color mutedText(BuildContext context) => context.tokens.textMuted;

  static Color borderColor(BuildContext context) => context.tokens.border;

  static Color accent(BuildContext context) => context.tokens.accent;

  @Deprecated('Use cardBg(context) for theme-aware cards')
  static const Color card = Colors.white;

  @Deprecated('Use canvasBg(context)')
  static const Color bg = Color(0xFFF8F7F4);

  @Deprecated('Use mutedText(context)')
  static const Color muted = Color(0xFF6B7280);

  @Deprecated('Use borderColor(context)')
  static const Color border = Color(0xFFE8E6E1);
}
