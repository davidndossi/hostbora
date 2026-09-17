import 'package:flutter/material.dart';


import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/widget/custom_app_bar.dart';

PreferredSizeWidget rentAppBar(
  String title, {
  List<Widget>? actions,
  Widget? leading,
  bool isCentered = true,
}) {
  return CustomAppBar(
    appBarTitleText: title,
    actions: actions,
    leading: leading,
    isCentered: isCentered,
    isBackButtonEnabled: leading == null,
  );
}

Widget rentCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE8ECF0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    },
  );
}

Widget rentSectionLabel(String text) {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
            color: tokens.textMuted,
          ),
        ),
      );
    },
  );
}

Widget rentTextField({
  required String label,
  TextEditingController? controller,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: TextStyle(color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: tokens.elevatedSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: tokens.border),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget rentPrimaryButton({
  required String label,
  VoidCallback? onPressed,
  IconData? icon,
  bool isLoading = false,
}) {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      );
    },
  );
}
