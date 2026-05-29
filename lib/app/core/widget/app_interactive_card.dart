import 'package:flutter/material.dart';

import '../theme/app_theme_tokens.dart';
import 'app_swipeable_card.dart';

/// Card with tap, optional long-press quick actions, and optional swipe handlers.
class AppInteractiveCard extends StatelessWidget {
  const AppInteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 12,
    this.color,
    this.onSwipeStartToEnd,
    this.onSwipeEndToStart,
    this.swipeStartLabel,
    this.swipeEndLabel,
    this.dismissKey,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final Color? color;
  final Future<void> Function()? onSwipeStartToEnd;
  final Future<void> Function()? onSwipeEndToStart;
  final String? swipeStartLabel;
  final String? swipeEndLabel;
  final Key? dismissKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget card = Material(
      color: color ?? tokens.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );

    if (onSwipeStartToEnd != null || onSwipeEndToStart != null) {
      card = AppSwipeableCard(
        dismissKey: dismissKey,
        onSwipeStartToEnd: onSwipeStartToEnd,
        onSwipeEndToStart: onSwipeEndToStart,
        startLabel: swipeStartLabel,
        endLabel: swipeEndLabel,
        child: card,
      );
    }

    return card;
  }
}
