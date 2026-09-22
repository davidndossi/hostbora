import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/locale/app_locale_controller.dart';
import '../../../core/service/app_update_service.dart';
import '../../../core/widget/tab_coach_mark.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/service/app_review_service.dart';
import '../../../data/local/service/lease_expiry_reminder_prompt_service.dart';
import '../../../data/local/service/account_sync_trigger.dart';
import '../../../data/remote/remote_data_source.dart';
import '../../../core/access/staff_access.dart';
import '../../../routes/app_pages.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '/app/core/base/base_controller.dart';
import '/app/core/utils/getx_instance_probe.dart';
import '/app/modules/dashboard/controllers/dashboard_controller.dart';
import '/app/modules/home/controllers/home_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/model/menu_code.dart';
import '/app/modules/maintenance_tasks/controllers/maintenance_tasks_controller.dart';

class MainController extends BaseController with WidgetsBindingObserver {
  final _selectedMenuCodeController = MenuCode.HOME.obs;

  MenuCode get selectedMenuCode => _selectedMenuCodeController.value;

  int get selectedMenuIndex => MenuCode.values.indexOf(selectedMenuCode);

  final lifeCardUpdateController = false.obs;
  final currentLocale = 'en'.obs;
  final title = ''.obs;

  /// Tabs that have been opened at least once (kept alive in [IndexedStack]).
  final builtMenuCodes = <MenuCode>{MenuCode.HOME}.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (Get.isRegistered<AppLocaleController>()) {
      final localeCtrl = Get.find<AppLocaleController>();
      currentLocale(localeCtrl.code.value);
      ever<String>(localeCtrl.code, (c) => currentLocale(c));
    }
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['initialMenu'] == 'home') {
      _applyMenuSelection(MenuCode.HOME);
    } else {
      _syncNavIndex(selectedMenuCode);
    }
    // All bindings are registered by the time MainController initialises,
    // so RemoteDataSource is available. Delay slightly so the UI paints first.
    // Soft prompts are sequenced so at most one appears (see LaunchPromptGate).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSessionIfNeeded();
      // Let Home paint before kicking remote sync (heavy UI refresh cascade).
      Future.delayed(const Duration(seconds: 3), triggerRemoteAccountSync);
      // Force-update can always show; soft update waits longer (see AppUpdateService)
      // so actionable lease prompts get first claim on the soft-prompt slot.
      _checkForUpdate();
      Future.delayed(const Duration(seconds: 2), _runSoftLaunchPrompts);
    });
  }

  /// Lease decision first (actionable), then store review — only one may show.
  Future<void> _runSoftLaunchPrompts() async {
    _maybePromptLeaseExpiry();
    // Give the lease dialog a moment to claim the gate before review evaluates.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _maybeShowReviewPrompt();
  }

  void _refreshSessionIfNeeded() {
    try {
      Get.find<SessionService>().ensureValidSession();
    } catch (_) {}
  }

  void _maybePromptLeaseExpiry() {
    try {
      Get.find<LeaseExpiryReminderPromptService>().maybePrompt();
    } catch (_) {}
  }

  void _maybeShowReviewPrompt() {
    try {
      Get.find<AppReviewService>().maybeShowPrompt();
    } catch (_) {
      // Best-effort — never block the main shell.
    }
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
      // Same value does not notify GetX listeners — force a refresh.
      _selectedMenuCodeController.refresh();
      builtMenuCodes.refresh();
      _syncNavIndex(selectedMenuCode);
    }
  }

  void _applyMenuSelection(MenuCode menuCode) {
    builtMenuCodes.add(menuCode);
    builtMenuCodes.refresh();
    if (_selectedMenuCodeController.value != menuCode) {
      _selectedMenuCodeController.value = menuCode;
    } else {
      _selectedMenuCodeController.refresh();
    }
    _syncNavIndex(menuCode);
  }

  void _syncNavIndex(MenuCode menuCode) {
    try {
      Get.find<BottomNavController>().updateSelectedIndex(
        MenuCode.values.indexOf(menuCode),
      );
    } catch (_) {}
  }

  Future<void> onMenuSelected(MenuCode menuCode) async {
    if (Get.isRegistered<StaffAccessStore>()) {
      final access = Get.find<StaffAccessStore>();
      if (!access.allowsMenu(menuCode.name)) {
        access.showDenied();
        return;
      }
    }
    _applyMenuSelection(menuCode);
    switch (menuCode) {
      case MenuCode.HOME:
        // Refresh only if Home is already constructed (avoid lazyPut stampede).
        if (GetxInstanceProbe.isAlive<HomeController>()) {
          unawaited(Get.find<HomeController>().loadHomeData(refresh: true));
        }
        break;
      case MenuCode.PROPERTIES:
        if (GetxInstanceProbe.isAlive<MyPropertiesController>()) {
          unawaited(Get.find<MyPropertiesController>().loadProperties());
        }
        // One-time tip; never stacks with another coach mark in-session.
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 600),
            TabCoachMark.maybeShowProperties,
          ),
        );
        break;
      case MenuCode.FINANCES:
        // User opened Finances — create Dashboard if needed, then load.
        if (Get.isRegistered<DashboardController>()) {
          unawaited(Get.find<DashboardController>().loadDashboard());
        }
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 600),
            TabCoachMark.maybeShowFinances,
          ),
        );
        break;
      case MenuCode.MAINTENANCE:
        if (GetxInstanceProbe.isAlive<MaintenanceTasksController>()) {
          unawaited(Get.find<MaintenanceTasksController>().loadTasks());
        }
        break;
      case MenuCode.MORE:
        break;
    }
  }

  void setDefaultLocale(final bool isUpdate) {
    if (!isUpdate) return;
    final next = currentLocale.value == 'sw' ? 'en' : 'sw';
    currentLocale.value = next;
    if (Get.isRegistered<AppLocaleController>()) {
      unawaited(Get.find<AppLocaleController>().setLanguage(next));
    } else {
      final locale =
          next == 'sw' ? const Locale('sw', 'TZ') : const Locale('en', 'US');
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
