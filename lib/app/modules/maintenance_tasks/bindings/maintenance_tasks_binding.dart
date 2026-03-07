import 'package:get/get.dart';

import '../controllers/maintenance_tasks_controller.dart';

class MaintenanceTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MaintenanceTasksController>(() => MaintenanceTasksController());
  }
}
