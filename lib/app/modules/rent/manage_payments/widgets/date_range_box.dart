import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/values/app_colors.dart';

class DateRangeBox extends StatelessWidget {
  final String startDate;
  final String endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const DateRangeBox({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateTile(
            title: 'Start Date',
            value: startDate,
            icon: Icons.calendar_today_outlined,
            onTap: onStartTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateTile(
            title: 'End Date',
            value: endDate,
            icon: Icons.event_available_outlined,
            onTap: onEndTap,
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final hasValue = value.trim().isNotEmpty;
    final fill = isDark
        ? (hasValue
            ? AppColors.colorPrimary.withValues(alpha: 0.22)
            : tokens.elevatedSurface)
        : (hasValue
            ? AppColors.colorPrimary.withValues(alpha: 0.08)
            : Colors.grey.shade100);
    final border = isDark
        ? (hasValue
            ? AppColors.colorPrimary
            : tokens.border.withValues(alpha: 0.7))
        : (hasValue ? AppColors.colorPrimary : Colors.grey.shade300);
    final titleColor = isDark ? tokens.textMuted : Colors.grey.shade600;
    final valueColor = isDark
        ? (hasValue ? Colors.white : tokens.textMuted)
        : (hasValue ? tokens.textPrimary : Colors.grey.shade700);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: hasValue ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.colorPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue ? value : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
