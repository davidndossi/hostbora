import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/values/app_values.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/controllers/main_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/main/model/menu_item.dart';

/// Closed (raised bump) — Figma 80:1002 Union. viewBox 368×113.901.
const double _kClosedDesignW = 368;
const double _kClosedDesignH = 113.901;
const double _kClosedBodyTop = 22.9014;

/// Open (center notch) — Figma 232:4510 / 311:17739 Subtract. viewBox 401×100.
const double _kOpenDesignW = 401;
const double _kOpenDesignH = 100;
const double _kOpenTopInset = 22.99;

/// Extra toe under the shaped path (kept small — not system safe-area).
const double _kNavToe = 12;

class BottomNavBar extends StatefulWidget {
  final Function(MenuCode menuCode) onNewMenuSelected;

  const BottomNavBar({super.key, required this.onNewMenuSelected});

  /// Overlay height for the closed bar at [width] (shape + toe).
  static double heightForWidth(double width) {
    final scale = width / _kClosedDesignW;
    return _kClosedDesignH * scale + _kNavToe;
  }

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shapeCtrl;
  late final Animation<double> _shapeAnim;
  Worker? _menuWorker;

  BottomNavController get navController => Get.find<BottomNavController>();

  @override
  void initState() {
    super.initState();
    _shapeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _shapeAnim = CurvedAnimation(
      parent: _shapeCtrl,
      curve: Curves.easeInOutCubic,
    );
    if (navController.moreMenuOpen.value) {
      _shapeCtrl.value = 1;
    }
    _menuWorker = ever<bool>(navController.moreMenuOpen, (open) {
      if (open) {
        _shapeCtrl.forward();
      } else {
        _shapeCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _menuWorker?.dispose();
    _shapeCtrl.dispose();
    super.dispose();
  }

  void _onFabTap() {
    navController.toggleMoreMenu();
  }

  void _onTabTap(MenuCode code) {
    if (navController.moreMenuOpen.value) {
      navController.closeMoreMenu();
    }
    widget.onNewMenuSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final closedScale = screenW / _kClosedDesignW;
    final shapeHeight = _kClosedDesignH * closedScale;
    final totalHeight = shapeHeight + _kNavToe;

    // final selectedItemColor = isDark
    //     ? theme.colorScheme.primary
    //     : const Color(0xFF34CBB9);
    final unselectedItemColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : AppColors.slateBlueGrey;
    final navBackgroundColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : AppColors.colorWhite;
    final closedFabBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFE2E8F0);
    final closedFabIcon = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);

    final leftItems = <BottomNavItem>[
      BottomNavItem(
        navTitle: appLocalization.home,
        iconSvgName: 'ic_home.svg',
        menuCode: MenuCode.HOME,
      ),
      BottomNavItem(
        navTitle: _capitalizeFirst(appLocalization.properties),
        iconSvgName: 'ic_building.svg',
        menuCode: MenuCode.PROPERTIES,
      ),
    ];
    final rightItems = <BottomNavItem>[
      BottomNavItem(
        navTitle: appLocalization.finances,
        iconSvgName: 'ic_wallet.svg',
        menuCode: MenuCode.FINANCES,
      ),
      BottomNavItem(
        navTitle: appLocalization.services,
        iconSvgName: 'ic_calendar_cog.svg',
        menuCode: MenuCode.MAINTENANCE,
      ),
    ];

    // Only the CustomPaint path is opaque — areas beside the bump stay clear.
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _shapeAnim,
        builder: (context, _) {
          final t = _shapeAnim.value;
          final bodyTop = lerpDouble(
            _kClosedBodyTop * closedScale,
            _kOpenTopInset * closedScale,
            t,
          )!;

          return Obx(() {
            final selectedCode = Get.find<MainController>().selectedMenuCode;
            final moreOpen = navController.moreMenuOpen.value;

            return SizedBox(
              height: totalHeight,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BottomNavShapePainter(
                        color: navBackgroundColor,
                        progress: t,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: bodyTop,
                    bottom: bottomInset,
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final item in leftItems)
                        Expanded(
                          child: _NavBarTile(
                            key: item.menuCode == MenuCode.PROPERTIES
                                ? navController.propertiesTabKey
                                : null,
                            item: item,
                            isSelected:
                                !moreOpen && item.menuCode == selectedCode,
                            selectedColor: theme.colorScheme.primary,
                            unselectedColor: unselectedItemColor,
                            onTap: () => _onTabTap(item.menuCode),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(height: lerpDouble(28, 8, t)),
                            Text(
                              appLocalization.more,
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.2,
                                foreground: moreOpen || t > 0.5
                                    ? (Paint()
                                      ..shader = LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          theme.colorScheme.primary,
                                          // Color(0xFF2FA5B7),
                                          // Color(0xFF2FB7A6),
                                          theme.colorScheme.primary
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 48, 16),
                                      ))
                                    : null,
                                color: moreOpen || t > 0.5
                                    ? null
                                    : unselectedItemColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      for (final item in rightItems)
                        Expanded(
                          child: _NavBarTile(
                            item: item,
                            isSelected:
                                !moreOpen && item.menuCode == selectedCode,
                            selectedColor: theme.colorScheme.primary,
                            unselectedColor: unselectedItemColor,
                            onTap: () => _onTabTap(item.menuCode),
                          ),
                        ),
                    ],
                  ),
                  ),
                  // Center FAB — gray "+" closed, teal "X" open (Figma 311:17710).
                  Positioned(
                    top: lerpDouble(6 * closedScale, -4 * closedScale, t),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        color: Color.lerp(
                          closedFabBg,
                          theme.colorScheme.primary,
                          t,
                        ),
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _onFabTap,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              t > 0.5 ? Icons.close_rounded : Icons.add,
                              size: 20,
                              color: Color.lerp(
                                closedFabIcon,
                                Colors.white,
                                t,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class _NavBarTile extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavBarTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppValues.iconDefaultSize,
                height: AppValues.iconDefaultSize,
                child: SvgPicture.asset(
                  'images/${item.iconSvgName}',
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.navTitle,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.2,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavShapePainter extends CustomPainter {
  _BottomNavShapePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final closed = _closedUnionPath(size);
    final open = _openSubtractPath(size);

    if (progress <= 0.001) {
      canvas.drawShadow(closed, Colors.black.withValues(alpha: 0.18), 12, true);
      canvas.drawPath(closed, Paint()..color = color);
      return;
    }
    if (progress >= 0.999) {
      canvas.drawShadow(open, Colors.black.withValues(alpha: 0.18), 12, true);
      canvas.drawPath(open, Paint()..color = color);
      return;
    }

    // Crossfade exact Figma paths while morphing.
    canvas.drawShadow(
      progress < 0.5 ? closed : open,
      Colors.black.withValues(alpha: 0.14),
      12,
      true,
    );
    canvas.drawPath(
      closed,
      Paint()..color = color.withValues(alpha: 1 - progress),
    );
    canvas.drawPath(
      open,
      Paint()..color = color.withValues(alpha: progress),
    );
  }

  @override
  bool shouldRepaint(covariant _BottomNavShapePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

Path _closedUnionPath(Size size) {
  final sx = size.width / _kClosedDesignW;
  final scaledH = _kClosedDesignH * sx;
  final p = Path();
  void m(double x, double y) => p.moveTo(x * sx, y * sx);
  void l(double x, double y) => p.lineTo(x * sx, y * sx);
  void c(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      p.cubicTo(x1 * sx, y1 * sx, x2 * sx, y2 * sx, x3 * sx, y3 * sx);

  m(184.458, 0);
  c(195.56, 0, 205.304, 5.80881, 210.819, 14.5528);
  c(213.703, 19.1262, 218.248, 22.9014, 223.655, 22.9014);
  l(367.084, 22.9014);
  c(367.59, 22.9014, 368, 23.3115, 368, 23.8174);
  l(368, 95.5801);
  c(368, 105.698, 359.798, 113.901, 349.68, 113.901);
  l(18.3203, 113.901);
  c(8.20228, 113.901, 0, 105.698, 0, 95.5801);
  l(0, 23.8174);
  c(0, 23.3115, 0.410134, 22.9014, 0.916016, 22.9014);
  l(145.262, 22.9014);
  c(150.669, 22.9014, 155.214, 19.1262, 158.098, 14.5528);
  c(163.613, 5.80889, 173.356, 0, 184.458, 0);
  p.close();

  if (size.height <= scaledH + 0.5) return p;
  final extended = Path()
    ..addRect(Rect.fromLTRB(0, scaledH - 2, size.width, size.height));
  return Path.combine(PathOperation.union, p, extended);
}

Path _openSubtractPath(Size size) {
  // Align open bar under the closed design's body top (Figma top: 22.99).
  final frameScale = size.width / _kClosedDesignW;
  final dy = _kOpenTopInset * frameScale;
  final sx = size.width / _kOpenDesignW;
  final scaledH = dy + _kOpenDesignH * sx;

  final p = Path();
  void m(double x, double y) => p.moveTo(x * sx, y * sx + dy);
  void l(double x, double y) => p.lineTo(x * sx, y * sx + dy);
  void c(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      p.cubicTo(
        x1 * sx,
        y1 * sx + dy,
        x2 * sx,
        y2 * sx + dy,
        x3 * sx,
        y3 * sx + dy,
      );

  // images/ic_bottom_nav_bar_shape_expanded.svg (Figma Subtract).
  m(400, 0);
  c(400.552, 0, 401, 0.447719, 401, 1);
  l(401, 80);
  c(401, 91.0457, 392.046, 100, 381, 100);
  l(20, 100);
  c(8.95431, 100, 0, 91.0457, 0, 80);
  l(0, 1);
  c(0, 0.447715, 0.447715, 0, 1, 0);
  l(158.754, 0);
  c(164.319, 0, 169.164, 3.47223, 172.636, 7.82088);
  c(179.048, 15.8532, 188.923, 21, 200, 21);
  c(211.077, 21, 220.952, 15.8532, 227.364, 7.82088);
  c(230.836, 3.47224, 235.681, 0, 241.246, 0);
  l(400, 0);
  p.close();

  if (size.height <= scaledH + 0.5) return p;
  final extended = Path()
    ..addRect(Rect.fromLTRB(0, scaledH - 2, size.width, size.height));
  return Path.combine(PathOperation.union, p, extended);
}
