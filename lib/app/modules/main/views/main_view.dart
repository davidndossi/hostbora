import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';

import '../../dashboard/views/dashboard_view.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/home_view.dart';
import '../../host_calendar/views/host_calendar_view.dart';
import '../../maintenance_tasks/views/maintenance_tasks_view.dart';
import '../../property_vault/views/property_vault_view.dart';
import '../../settings/views/settings_view.dart';
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
    return Container(
      key: UniqueKey(),
      child: Obx(() => getPageOnSelectedMenu(controller.selectedMenuCode)),
    );
  }

  @override
  Widget? floatingActionButton() {
    // return Obx(() {
      // if (controller.selectedMenuCode != MenuCode.HOME) return null;
      final homeController = Get.find<HomeController>();
      return ExpandableFab(
        type: ExpandableFabType.fan,
        pos: ExpandableFabPos.right,
        fanAngle: 60,
        margin: const EdgeInsets.only(bottom: 8),
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.4),
          blur: 6,
        ),
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.colorPrimary,
          shape: const CircleBorder(),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.small,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.colorPrimary,
          shape: const CircleBorder(),
        ),
        children: [
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: AppColors.colorWhite,
            foregroundColor: AppColors.colorPrimary,
            onPressed: homeController.addExpense,
            tooltip: 'Add expense',
            child: const Icon(Icons.receipt_long_outlined),
          ),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: AppColors.colorWhite,
            foregroundColor: AppColors.colorPrimary,
            onPressed: homeController.addPayment,
            tooltip: 'Add payment',
            child: const Icon(Icons.payment_outlined),
          ),
        ],
      );
    // });
  }

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() {
    return ExpandableFab.location;
  }

  @override
  Widget? bottomNavigationBar() {
    return BottomNavBar(onNewMenuSelected: controller.onMenuSelected);
  }

  final HomeView _homeView = HomeView();
  DashboardView? _dashboardView;
  HostCalendarView? _hostCalendarView;
  MaintenanceTasksView? _maintenanceTasksView;
  PropertyVaultView? _propertyVaultView;
  SettingsView? _settingsView;

  Widget getPageOnSelectedMenu(MenuCode menuCode) {
    switch (menuCode) {
      case MenuCode.HOME:
        return _homeView;
      case MenuCode.DASHBOARD:
        _dashboardView ??= DashboardView();
        return _dashboardView!;
      case MenuCode.CALENDAR:
        _hostCalendarView ??= HostCalendarView();
        return _hostCalendarView!;
      case MenuCode.TASKS:
        _maintenanceTasksView ??= MaintenanceTasksView();
        return _maintenanceTasksView!;
      case MenuCode.VAULT:
        _propertyVaultView ??= PropertyVaultView();
        return _propertyVaultView!;
      case MenuCode.SETTINGS:
        _settingsView ??= SettingsView();
        return _settingsView!;
    }
  }
}
