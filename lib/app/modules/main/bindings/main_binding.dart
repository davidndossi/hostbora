import 'package:get/get.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../maintenance_tasks/controllers/maintenance_tasks_controller.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '../../more/controllers/more_controller.dart';
import '../../other/controllers/other_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '/app/modules/main/controllers/bottom_nav_controller.dart';
import '/app/modules/main/controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BottomNavController>(BottomNavController(), permanent: true);
    // Permanent: after long background / app-lock overlays, fenix recreation
    // left MainView's Obx subscribed to a disposed Rx while the nav bar
    // (also permanent) kept updating — tabs changed color but pages did not.
    if (!Get.isRegistered<MainController>()) {
      Get.put<MainController>(MainController(), permanent: true);
    }
    Get.lazyPut<OtherController>(() => OtherController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<MyPropertiesController>(
      () => MyPropertiesController(),
      fenix: true,
    );
    Get.lazyPut<MaintenanceTasksController>(
      () => MaintenanceTasksController(),
      fenix: true,
    );
    Get.lazyPut<HostCalendarController>(
      () => HostCalendarController(),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    Get.lazyPut<MoreController>(MoreController.new, fenix: true);
  }
}
