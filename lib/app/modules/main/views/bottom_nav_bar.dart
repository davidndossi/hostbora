import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/values/app_values.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/main/model/menu_item.dart';

// ignore: must_be_immutable
class BottomNavBar extends StatelessWidget {
  final Function(MenuCode menuCode) onNewMenuSelected;

  BottomNavBar({super.key, required this.onNewMenuSelected});

  late AppLocalizations appLocalization;

  BottomNavController get navController => Get.find<BottomNavController>();

  final Key bottomNavKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    appLocalization = AppLocalizations.of(context)!;

    Color selectedItemColor = AppColors.colorPrimary;
    Color unselectedItemColor = AppColors.slateBlueGrey;
    List<BottomNavItem> navItems = _getNavItems();

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: AppColors.colorWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = navController.selectedIndex == index;
                return Expanded(
                  child: _NavBarTile(
                    item: item,
                    isSelected: isSelected,
                    selectedColor: selectedItemColor,
                    unselectedColor: unselectedItemColor,
                    onTap: () {
                      navController.updateSelectedIndex(index);
                      onNewMenuSelected(item.menuCode);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  List<BottomNavItem> _getNavItems() {
    return [
      BottomNavItem(
        navTitle: appLocalization.home,
        iconSvgName: 'ic_home.svg',
        menuCode: MenuCode.HOME),
      BottomNavItem(
        navTitle: appLocalization.dashboard,
        iconSvgName: 'ic_dashboard.svg',
        menuCode: MenuCode.DASHBOARD),
      BottomNavItem(
        navTitle: appLocalization.calendar,
        iconSvgName: 'ic_booking.svg',
        menuCode: MenuCode.CALENDAR),
      BottomNavItem(
        navTitle: appLocalization.tasks,
        iconSvgName: 'tick-circle.svg',
        menuCode: MenuCode.TASKS),
      BottomNavItem(
        navTitle: appLocalization.vault,
        iconSvgName: 'ic_vault.svg',
        menuCode: MenuCode.VAULT),
      BottomNavItem(
        navTitle: appLocalization.settings,
        iconSvgName: 'ic_settings.svg',
        menuCode: MenuCode.SETTINGS),
    ];
  }
}

class _NavBarTile extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavBarTile({
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'images/${item.iconSvgName}',
                height: AppValues.iconDefaultSize,
                width: AppValues.iconDefaultSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 4),
              Text(
                item.navTitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 7,
                child: isSelected
                    ? Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FabBottomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    const double cornerRadius = 20.0;
    const double notchWidth = 80.0;
    const double notchHeight = 45.0;

    // Start from the top left corner
    path.moveTo(0, cornerRadius);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top straight line until just before the notch
    path.lineTo(size.width - notchWidth - cornerRadius/2, 0);

    // Notch top-left corner
    path.quadraticBezierTo(
      size.width - notchWidth,
      0,
      size.width - notchWidth,
      cornerRadius/2,
    );

    path.lineTo(size.width - notchWidth, notchHeight - cornerRadius);

    // Notch bottom-left corner
    path.quadraticBezierTo(
      size.width - notchWidth,
      notchHeight,
      size.width - notchWidth + cornerRadius,
      notchHeight,
    );

    path.lineTo(size.width - 1.5*cornerRadius, notchHeight);

    // Notch bottom-right corner
    path.quadraticBezierTo(
      size.width - cornerRadius/2,
      notchHeight,
      size.width - cornerRadius/2,
      notchHeight - cornerRadius,
    );

    // Notch top-right corner
    path.lineTo(size.width - cornerRadius/2, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      cornerRadius,
    );

    // Right straight line and bottom-right rounded corner
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    // Bottom straight line
    path.lineTo(cornerRadius, size.height);

    // Bottom-left rounded corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
