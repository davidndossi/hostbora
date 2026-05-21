import 'package:get/get.dart';

import '../controllers/calendar_sync_controller.dart';

class CalendarSyncBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CalendarSyncController>(CalendarSyncController.new);
  }
}
