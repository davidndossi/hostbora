import 'package:get/get.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../maintenance_tasks/controllers/maintenance_tasks_controller.dart';
import '../../other/controllers/other_controller.dart';
import '../../property_vault/controllers/property_vault_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BottomNavController>(BottomNavController(), permanent: true);
    Get.lazyPut<MainController>(
      () => MainController(),
      fenix: true,
    );
    Get.lazyPut<OtherController>(
      () => OtherController(),
      fenix: true,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
      fenix: true,
    );
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
      fenix: true,
    );
    Get.lazyPut<HostCalendarController>(
      () => HostCalendarController(),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
      fenix: true,
    );
  }
}
