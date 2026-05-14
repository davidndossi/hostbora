import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_values.dart';

/// Standard decorations aligned with Figma HOST BORA design.
/// See docs/DESIGN_SYSTEM.md and Figma node 2001-1281.
abstract class AppDecorations {
  /// Card style: white surface, 12px radius, subtle shadow (Figma spec).
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Same as [card] with a custom border radius.
  static BoxDecoration cardWithRadius(double radius) => BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
