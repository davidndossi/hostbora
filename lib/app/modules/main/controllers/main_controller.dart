import 'dart:ui';

import 'package:get/get.dart';

import '../../../data/local/preference/preference_manager.dart';
import '/app/core/base/base_controller.dart';
import '/app/modules/dashboard/controllers/dashboard_controller.dart';
import '/app/modules/home/controllers/home_controller.dart';
import '/app/modules/host_calendar/controllers/host_calendar_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/model/menu_code.dart';

class MainController extends BaseController {
  final _selectedMenuCodeController = MenuCode.HOME.obs;

  MenuCode get selectedMenuCode => _selectedMenuCodeController.value;

  final isAdmin = false.obs;
  final isLeader = false.obs;
  final lifeCardUpdateController = false.obs;
  final currentLocale = 'en'.obs;
  final title = ''.obs;

  final PreferenceManager _preferenceManager =
  Get.find(tag: (PreferenceManager).toString());

  @override
  void onInit() async {
    super.onInit();
    isLeader(await _preferenceManager.getBool('isLeader'));
    isAdmin(await _preferenceManager.getBool('isAdmin'));
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['initialMenu'] == 'home') {
      _selectedMenuCodeController(MenuCode.HOME);
      try {
        Get.find<BottomNavController>().updateSelectedIndex(0);
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
      case MenuCode.DASHBOARD:
        if (Get.isRegistered<DashboardController>()) {
          await Get.find<DashboardController>().loadDashboard();
        }
        break;
      case MenuCode.CALENDAR:
        await HostCalendarController.refreshIfRegistered();
        break;
      case MenuCode.SETTINGS:
        break;
    }
  }

  void setDefaultLocale(final bool isUpdate) {
    // _storageService.write('language', currentLocale.value);

    // String locale = currentLocale.value == 'sw' ? 'sw_TZ' : 'en_US';
    // initializeDateFormatting(locale, null);
    // Intl.defaultLocale = locale;

    if (isUpdate) {
      Locale locale = currentLocale.value == 'sw' ? const Locale('sw', 'TZ') :
      const Locale('en', 'US');
      Get.updateLocale(locale);
    }
  }
}
