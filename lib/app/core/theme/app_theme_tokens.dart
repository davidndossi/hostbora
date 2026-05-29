import 'package:flutter/material.dart';

import '../values/app_colors.dart';

/// Semantic colors aligned with [docs/DESIGN_SYSTEM.md] and Rent shell dark surfaces.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.cardBackground,
    required this.elevatedSurface,
    required this.scaffoldBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.success,
    required this.warning,
    required this.accent,
  });

  final Color cardBackground;
  final Color elevatedSurface;
  final Color scaffoldBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color success;
  final Color warning;
  final Color accent;

  static const light = AppThemeTokens(
    cardBackground: AppColors.colorWhite,
    elevatedSurface: AppColors.colorWhite,
    scaffoldBackground: AppColors.pageBackground,
    textPrimary: AppColors.textColorPrimary,
    textSecondary: AppColors.textColorSecondary,
    textMuted: AppColors.designPlaceholder,
    border: AppColors.designInputBorder,
    skeletonBase: Color(0xFFE8EAED),
    skeletonHighlight: Color(0xFFF4F5F7),
    success: AppColors.paaYanguSuccess,
    warning: AppColors.paaYanguWarm,
    accent: AppColors.colorPrimary,
  );

  static const dark = AppThemeTokens(
    cardBackground: Color(0xFF2C2C2E),
    elevatedSurface: Color(0xFF3A3A3C),
    scaffoldBackground: Color(0xFF1C1C1E),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0B3BA),
    textMuted: Color(0xFF8E8E93),
    border: Color(0xFF3A3A3C),
    skeletonBase: Color(0xFF3A3A3C),
    skeletonHighlight: Color(0xFF48484A),
    success: AppColors.paaYanguSuccess,
    warning: AppColors.paaYanguWarm,
    accent: Color(0xFF5EC9C3),
  );

  @override
  AppThemeTokens copyWith({
    Color? cardBackground,
    Color? elevatedSurface,
    Color? scaffoldBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? success,
    Color? warning,
    Color? accent,
  }) {
    return AppThemeTokens(
      cardBackground: cardBackground ?? this.cardBackground,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeTokens(
      cardBackground: lerpColor(cardBackground, other.cardBackground),
      elevatedSurface: lerpColor(elevatedSurface, other.elevatedSurface),
      scaffoldBackground: lerpColor(scaffoldBackground, other.scaffoldBackground),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
      textSecondary: lerpColor(textSecondary, other.textSecondary),
      textMuted: lerpColor(textMuted, other.textMuted),
      border: lerpColor(border, other.border),
      skeletonBase: lerpColor(skeletonBase, other.skeletonBase),
      skeletonHighlight: lerpColor(skeletonHighlight, other.skeletonHighlight),
      success: lerpColor(success, other.success),
      warning: lerpColor(warning, other.warning),
      accent: lerpColor(accent, other.accent),
    );
  }
}

extension AppThemeTokensContext on BuildContext {
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppThemeTokens.light;
}
