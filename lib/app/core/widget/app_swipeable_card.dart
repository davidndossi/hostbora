import 'package:flutter/material.dart';

import '../theme/app_theme_tokens.dart';
import '../values/app_colors.dart';

/// Horizontal swipe actions that do not remove the child (confirmDismiss returns false).
class AppSwipeableCard extends StatelessWidget {
  const AppSwipeableCard({
    super.key,
    required this.child,
    this.onSwipeStartToEnd,
    this.onSwipeEndToStart,
    this.startLabel,
    this.endLabel,
    this.startIcon = Icons.schedule,
    this.endIcon = Icons.check_circle_outline,
    this.startColor,
    this.endColor,
    this.dismissKey,
  });

  final Widget child;
  final Future<void> Function()? onSwipeStartToEnd;
  final Future<void> Function()? onSwipeEndToStart;
  final String? startLabel;
  final String? endLabel;
  final IconData startIcon;
  final IconData endIcon;
  final Color? startColor;
  final Color? endColor;
  final Key? dismissKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasStart = onSwipeStartToEnd != null;
    final hasEnd = onSwipeEndToStart != null;
    if (!hasStart && !hasEnd) return child;

    return Dismissible(
      key: dismissKey ?? ValueKey('swipe_${child.hashCode}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && hasStart) {
          await onSwipeStartToEnd!();
        } else if (direction == DismissDirection.endToStart && hasEnd) {
          await onSwipeEndToStart!();
        }
        return false;
      },
      background: hasStart
          ? _SwipeBg(
              alignment: Alignment.centerLeft,
              color: startColor ?? tokens.accent.withValues(alpha: 0.88),
              icon: startIcon,
              label: startLabel ?? '',
            )
          : null,
      secondaryBackground: hasEnd
          ? _SwipeBg(
              alignment: Alignment.centerRight,
              color: endColor ?? AppColors.paaYanguSuccess.withValues(alpha: 0.9),
              icon: endIcon,
              label: endLabel ?? '',
            )
          : null,
      child: child,
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ] else ...[
            if (label.isNotEmpty) ...[
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
