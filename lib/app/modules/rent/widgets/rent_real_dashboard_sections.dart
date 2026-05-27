import 'package:flutter/material.dart';

import '../rent_theme.dart';
import 'rent_ui.dart';

Widget rentSectionTitle(String eyebrow, String title, {String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: RentTheme.muted,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: RentTheme.navy,
          height: 1.1,
        ),
      ),
      if (subtitle != null && subtitle.trim().isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: RentTheme.muted,
            height: 1.35,
          ),
        ),
      ],
    ],
  );
}

Widget rentMetricTile({
  required String label,
  required String value,
  IconData? icon,
  Color? accent,
}) {
  final tone = accent ?? RentTheme.conciergeTeal;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFFBFAF8)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: RentTheme.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        if (icon != null)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: tone),
          ),
        if (icon != null) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: RentTheme.navy,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: RentTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget rentMetricGrid(List<Widget> tiles) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final columns = wide ? 3 : 2;
      return GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: wide ? 2.5 : 2.35,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      );
    },
  );
}

Widget rentKpiRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: RentTheme.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: valueColor ?? RentTheme.navy,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

Widget rentSplitBar({
  required double first,
  required double second,
  String firstLabel = 'Income',
  String secondLabel = 'Expense',
}) {
  final total = (first + second) <= 0 ? 1.0 : first + second;
  final firstFlex = ((first / total) * 1000).round().clamp(1, 1000);
  final secondFlex = ((second / total) * 1000).round().clamp(1, 1000);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 12,
          child: Row(
            children: [
              Expanded(
                flex: firstFlex,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [RentTheme.conciergeTeal, RentTheme.teal],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: secondFlex,
                child: Container(color: RentTheme.warnFg.withValues(alpha: 0.82)),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          _legend(firstLabel, RentTheme.conciergeTeal),
          const SizedBox(width: 16),
          _legend(secondLabel, RentTheme.warnFg.withValues(alpha: 0.82)),
        ],
      ),
    ],
  );
}

Widget _legend(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: RentTheme.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget rentInsightCard({required String title, required String message}) {
  return rentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: RentTheme.conciergeTeal,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: RentTheme.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: RentTheme.muted,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
