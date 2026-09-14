import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dashboard/views/dashboard_view.dart';
import '../../home/views/home_view.dart';
import '../../maintenance_tasks/views/maintenance_tasks_view.dart';
import '../../my_properties/views/my_properties_view.dart';
import '../../more/views/more_view.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/base/base_view.dart';
import '/app/modules/main/controllers/main_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/main/views/bottom_nav_bar.dart';
import '/app/modules/main/views/more_options_sheet.dart';

// ignore: must_be_immutable
class MainView extends BaseView<MainController> {
  MainView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    // IndexedStack keeps visited tabs alive and switches by index so a stale
    // Element cannot keep showing the previous page after resume.
    //
    // Bottom nav is stacked here (not Scaffold.bottomNavigationBar): the scaffold
    // slot paints an opaque band and inflate MediaQuery padding to the bar
    // height, so bump cutouts never show real page content underneath.
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Obx(() {
          final selected = controller.selectedMenuCode;
          final built = controller.builtMenuCodes;
          return IndexedStack(
            index: MenuCode.values.indexOf(selected),
            sizing: StackFit.expand,
            children: [
              for (final code in MenuCode.values)
                KeyedSubtree(
                  key: ValueKey(code),
                  child: built.contains(code)
                      ? getPageOnSelectedMenu(code)
                      : const SizedBox.shrink(),
                ),
            ],
          );
        }),
        // Figma More v2 overlay (scrim + Find More Options sheet).
        const MoreOptionsOverlay(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomNavBar(onNewMenuSelected: controller.onMenuSelected),
        ),
      ],
    );
  }

  /// Tabs provide their own safe areas; avoid padding that would lift the
  /// overlaid nav and leave an opaque strip under the bump cutouts.
  @override
  bool get safeAreaTop => false;

  @override
  bool get safeAreaBottom => false;

  @override
  Widget? floatingActionButton() => Obx(() {
    // Hide page FAB while the center More menu is open (Figma 311:17710).
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().moreMenuOpen.value) {
      return const SizedBox.shrink();
    }
    final menu = controller.selectedMenuCode;
    final isMaintenanceTab = menu == MenuCode.MAINTENANCE;
    final isPropertiesTab = menu == MenuCode.PROPERTIES;
    final isSw = controller.currentLocale.value == 'sw';

    if (isPropertiesTab) {
      return FloatingActionButton.extended(
        onPressed: controller.addProperty,
        backgroundColor: AppColors.designAccent,
        icon: const Icon(Icons.add_home_work_rounded, color: Colors.white, size: 22),
        label: Text(
          isSw ? 'Ongeza Mali' : 'Add Property',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }

    // Home / Finances / More: AI FAB (Create lives on Home as an in-page CTA).
    return FloatingActionButton(
      onPressed: isMaintenanceTab
          ? controller.addTask
          : controller.aiManager,
      backgroundColor: AppColors.designAccent,
      child: Icon(
        isMaintenanceTab ? Icons.add : Icons.auto_awesome,
        color: AppColors.textColorWhite,
        size: 28,
      ),
    );
  });

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() =>
      const _EndFloatAboveBottomNav();

  @override
  Widget? bottomNavigationBar() => null;

  final HomeView _homeView = HomeView();
  MyPropertiesView? _myPropertiesView;
  DashboardView? _dashboardView;
  MaintenanceTasksView? _maintenanceTasksView;
  MoreView? _moreView;

  Widget getPageOnSelectedMenu(MenuCode menuCode) {
    switch (menuCode) {
      case MenuCode.HOME:
        return _homeView;
      case MenuCode.PROPERTIES:
        _myPropertiesView ??= MyPropertiesView();
        return _myPropertiesView!;
      case MenuCode.FINANCES:
        _dashboardView ??= DashboardView();
        return _dashboardView!;
      case MenuCode.MAINTENANCE:
        _maintenanceTasksView ??= MaintenanceTasksView();
        return _maintenanceTasksView!;
      case MenuCode.MORE:
        _moreView ??= MoreView();
        return _moreView!;
    }
  }
}

/// [endFloat], lifted clear of the overlaid [BottomNavBar] (Services sits under
/// the default end-float spot when the bar is not in Scaffold.bottomNavigationBar).
class _EndFloatAboveBottomNav extends FloatingActionButtonLocation {
  const _EndFloatAboveBottomNav();

  static const _gapAboveNav = 12.0;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final base = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    final navHeight = BottomNavBar.heightForWidth(geometry.scaffoldSize.width);
    // endFloat already clears [minInsets.bottom]; only lift by the part of the
    // nav that sits above that inset so we don't double-count the home indicator.
    final lift = (navHeight - geometry.minInsets.bottom).clamp(0.0, navHeight);
    return Offset(base.dx, base.dy - lift - _gapAboveNav);
  }
}
