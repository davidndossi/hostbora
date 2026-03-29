import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../rent_theme.dart';

PreferredSizeWidget rentAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: RentTheme.bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RentTheme.navy, size: 20),
      onPressed: Get.back,
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: RentTheme.navy,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    centerTitle: false,
    actions: actions,
  );
}

Widget rentCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: RentTheme.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: RentTheme.border),
    ),
    child: child,
  );
}

Widget rentSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: RentTheme.teal,
      ),
    ),
  );
}

Widget rentTextField({
  required String label,
  TextEditingController? controller,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: RentTheme.navy, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: RentTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: RentTheme.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RentTheme.teal, width: 1.5),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget rentPrimaryButton({required String label, VoidCallback? onPressed, IconData? icon}) {
  return SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: RentTheme.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );
}
