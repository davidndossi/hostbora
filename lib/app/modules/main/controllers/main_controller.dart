import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/service/app_update_service.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/remote/remote_data_source.dart';
import '../../../routes/app_pages.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '/app/core/base/base_controller.dart';
import '/app/modules/dashboard/controllers/dashboard_controller.dart';
import '/app/modules/home/controllers/home_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/maintenance_tasks/controllers/maintenance_tasks_controller.dart';

class MainController extends BaseController with WidgetsBindingObserver {
  final _selectedMenuCodeController = MenuCode.HOME.obs;

  MenuCode get selectedMenuCode => _selectedMenuCodeController.value;

  final lifeCardUpdateController = false.obs;
  final currentLocale = 'en'.obs;
  final title = ''.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['initialMenu'] == 'home') {
      _selectedMenuCodeController(MenuCode.HOME);
      try {
        Get.find<BottomNavController>().updateSelectedIndex(0);
      } catch (_) {}
    }
    // All bindings are registered by the time MainController initialises,
    // so RemoteDataSource is available. Delay slightly so the UI paints first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
      triggerRemoteAccountSync();
    });
  }

  void _checkForUpdate() {
    try {
      final remote = Get.find<RemoteDataSource>(
        tag: (RemoteDataSource).toString(),
      );
      AppUpdateService(remote).checkAndNotify();
    } catch (_) {
      // Best-effort — never crash the app over a version check.
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Re-notify the current page selection when the app returns to foreground
  /// so that any Obx subscribers that missed updates while paused are refreshed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-assign the same value to force all Obx listeners to rebuild.
      final current = _selectedMenuCodeController.value;
      _selectedMenuCodeController.value = current;
      // Also nudge BottomNavController so the nav bar visual state is fresh.
      try {
        final nav = Get.find<BottomNavController>();
        final idx = nav.selectedIndex;
        nav.updateSelectedIndex(idx);
      } catch (_) {}
    }
  }

  Future<void> onMenuSelected(MenuCode menuCode) async {
    _selectedMenuCodeController(menuCode);
    switch (menuCode) {
      case MenuCode.HOME:
        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().loadHomeData();
        }
        break;
      case MenuCode.PROPERTIES:
        if (Get.isRegistered<MyPropertiesController>()) {
          await Get.find<MyPropertiesController>().loadProperties();
        }
        break;
      case MenuCode.FINANCES:
        if (Get.isRegistered<DashboardController>()) {
          await Get.find<DashboardController>().loadDashboard();
        }
        break;
      case MenuCode.MAINTENANCE:
        if (Get.isRegistered<MaintenanceTasksController>()) {
          await Get.find<MaintenanceTasksController>().loadTasks();
        }
        break;
      case MenuCode.MORE:
        break;
    }
  }

  void setDefaultLocale(final bool isUpdate) {
    // _storageService.write('language', currentLocale.value);

    // String locale = currentLocale.value == 'sw' ? 'sw_TZ' : 'en_US';
    // initializeDateFormatting(locale, null);
    // Intl.defaultLocale = locale;

    if (isUpdate) {
      Locale locale = currentLocale.value == 'sw'
          ? const Locale('sw', 'TZ')
          : const Locale('en', 'US');
      Get.updateLocale(locale);
    }
  }

  void aiManager() => Get.toNamed(Routes.AI_MANAGER);

  Future<void> addTask() async {
    final result = await Get.toNamed(Routes.ADD_TASK);
    if (result == true && Get.isRegistered<MaintenanceTasksController>()) {
      Get.find<MaintenanceTasksController>().loadTasks();
    }
  }

  Future<void> addProperty() async {
    final result = await Get.toNamed(Routes.ADD_LISTING);
    if (result == true && Get.isRegistered<MyPropertiesController>()) {
      Get.find<MyPropertiesController>().loadProperties();
    }
  }
}
