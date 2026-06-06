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
    return Container(
      key: UniqueKey(),
      child: Obx(() => getPageOnSelectedMenu(controller.selectedMenuCode)),
    );
  }

  @override
  Widget? floatingActionButton() => Obx(() {
    final isMaintenanceTab =
        controller.selectedMenuCode == MenuCode.MAINTENANCE;
    return FloatingActionButton(
      onPressed: isMaintenanceTab ? controller.addTask : controller.aiManager,
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
