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
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/main/views/bottom_nav_bar.dart';

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
    return Obx(() {
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
    });
  }

  @override
  Widget? floatingActionButton() => Obx(() {
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
      FloatingActionButtonLocation.endFloat;

  @override
  Widget? bottomNavigationBar() {
    return BottomNavBar(onNewMenuSelected: controller.onMenuSelected);
  }

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
