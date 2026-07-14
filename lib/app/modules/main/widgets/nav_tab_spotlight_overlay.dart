import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../controllers/bottom_nav_controller.dart';

/// Shows a one-time dimmed spotlight around the "Properties" bottom-nav tab,
/// with a short tooltip nudging brand-new (zero-property) users there.
///
/// No-ops silently if the tab's on-screen position can't be resolved (e.g.
/// the bottom nav isn't currently mounted).
Future<void> showPropertiesTabSpotlight({required bool isSw}) async {
  final ctx = Get.overlayContext ?? Get.context;
  if (ctx == null || !ctx.mounted) return;

  Rect? targetRect;
  try {
    final navController = Get.find<BottomNavController>();
    final renderObject =
        navController.propertiesTabKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.attached) {
      final origin = renderObject.localToGlobal(Offset.zero);
      targetRect = Rect.fromLTWH(
        origin.dx,
        origin.dy,
        renderObject.size.width,
        renderObject.size.height,
      );
    }
  } catch (_) {
    // Bottom nav not registered/mounted yet — skip the spotlight this time.
  }

  if (targetRect == null) return;

  await showGeneralDialog<void>(
    context: ctx,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => _NavTabSpotlightOverlay(
      targetRect: targetRect!,
      isSw: isSw,
    ),
  );
}

class _NavTabSpotlightOverlay extends StatelessWidget {
  const _NavTabSpotlightOverlay({required this.targetRect, required this.isSw});

  final Rect targetRect;
  final bool isSw;

  static const double _holeRadius = 18;
  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final holeRect = targetRect.inflate(6);
    final screenSize = MediaQuery.sizeOf(context);
    final tooltipWidth = (screenSize.width - 32).clamp(0.0, 300.0);
    var tooltipLeft = holeRect.center.dx - tooltipWidth / 2;
    tooltipLeft = tooltipLeft.clamp(16.0, screenSize.width - tooltipWidth - 16);
    final tooltipBottom = screenSize.height - holeRect.top + _gap;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: CustomPaint(
                painter: _SpotlightPainter(
                  holeRect: holeRect,
                  holeRadius: _holeRadius,
                ),
              ),
            ),
          ),
          Positioned(
            left: tooltipLeft,
            bottom: tooltipBottom,
            width: tooltipWidth,
            child: _TooltipCard(isSw: isSw),
          ),
        ],
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({required this.isSw});

  final bool isSw;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? context.tokens.cardBackground : Colors.white,
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw
                  ? 'Ongeza mali yako ya kwanza hapa'
                  : 'Add your first property here',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSw
                  ? 'Bofya kichupo cha "Mali" kuanzisha uhifadhi, kodi na mapato.'
                  : 'Tap the "Properties" tab to start tracking bookings, rent, and income.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFFAEAEB2)
                    : const Color(0xFF4B5563),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(isSw ? 'Nimeelewa' : 'Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.holeRect, required this.holeRadius});

  final Rect holeRect;
  final double holeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backdropPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holeRRect = RRect.fromRectAndRadius(
      holeRect,
      Radius.circular(holeRadius),
    );
    final holePath = Path()..addRRect(holeRRect);
    final dimmedPath = Path.combine(
      PathOperation.difference,
      backdropPath,
      holePath,
    );

    canvas.drawPath(
      dimmedPath,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    canvas.drawRRect(
      holeRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect || oldDelegate.holeRadius != holeRadius;
}
