import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';

import '../../dashboard/views/dashboard_view.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/home_view.dart';
import '../../host_calendar/views/host_calendar_view.dart';
import '../../settings/views/settings_view.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/base/base_view.dart';
import '/app/modules/main/controllers/main_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/main/views/bottom_nav_bar.dart';

// ignore: must_be_immutable
class MainView extends BaseView<MainController> {
  MainView({super.key});

  final _expandableFabKey = GlobalKey<ExpandableFabState>();

  String _t({required String en, required String sw}) {
    final code = Get.locale?.languageCode ?? 'en';
    return code == 'sw' ? sw : en;
  }

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
    final context = Get.context;
    final theme = context != null ? Theme.of(context) : null;
    final isDark = theme?.brightness == Brightness.dark;
    final homeController = Get.find<HomeController>();
    return ExpandableFab(
      key: _expandableFabKey,
      type: ExpandableFabType.fan,
      pos: ExpandableFabPos.right,
      fanAngle: 90,
      margin: const EdgeInsets.only(bottom: 8),
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withValues(alpha: 0.4),
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
        FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: isDark == true
              ? theme!.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          foregroundColor: isDark == true
              ? theme!.colorScheme.primary
              : AppColors.colorPrimary,
          onPressed: () {
            _closeFabThen(() => homeController.addListing());
          },
          tooltip: _t(en: 'Add Listing', sw: 'Ongeza Mjengo'),
          label: Text(_t(en: 'Property', sw: 'Mjengo'), style: TextStyle(fontSize: 12)),
          icon: Icon(
            Icons.house_outlined,
            size: 18,
          ),
        ),
        FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: isDark == true
              ? theme!.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          foregroundColor: isDark == true
              ? theme!.colorScheme.primary
              : AppColors.colorPrimary,
          onPressed: () {
            _closeFabThen(() => homeController.addExpense());
          },
          tooltip: _t(en: 'Add expense', sw: 'Ongeza matumizi'),
          label: Text(_t(en: 'Expense', sw: 'Matumizi'), style: TextStyle(fontSize: 12)),
          icon: Icon(
            Icons.receipt_long_outlined,
            size: 18,
          ),
        ),
        FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: isDark == true
              ? theme!.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          foregroundColor: isDark == true
              ? theme!.colorScheme.primary
              : AppColors.colorPrimary,
          onPressed: () {
            _closeFabThen(() => homeController.addPayment());
          },
          tooltip: _t(en: 'Add payment', sw: 'Ongeza malipo'),
          label: Text(_t(en: 'Payment', sw: 'Malipo'), style: TextStyle(fontSize: 12)),
          icon: Icon(
            Icons.payment_outlined,
            size: 18,
          ),
        ),
      ],
    );
  }

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() {
    return ExpandableFab.location;
  }

  void _closeFabThen(VoidCallback action) {
    final state = _expandableFabKey.currentState;
    if (state != null && state.isOpen) {
      state.toggle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        action();
      });
    } else {
      action();
    }
  }

  @override
  Widget? bottomNavigationBar() {
    return BottomNavBar(onNewMenuSelected: controller.onMenuSelected);
  }

  final HomeView _homeView = HomeView();
  DashboardView? _dashboardView;
  HostCalendarView? _hostCalendarView;
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
      case MenuCode.SETTINGS:
        _settingsView ??= SettingsView();
        return _settingsView!;
    }
  }
}
