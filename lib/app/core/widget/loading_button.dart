import 'package:flutter/material.dart';

import '../theme/app_theme_tokens.dart';
import '../values/app_values.dart';

/// Primary action button with inline loading — avoids full-screen loaders on submit.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.style,
    this.minimumSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonStyle? style;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: style ??
            ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              minimumSize: minimumSize ??
                  const Size.fromHeight(AppValues.formButtonHeight),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
              ),
            ),
        child: child,
      ),
    );
  }
}
