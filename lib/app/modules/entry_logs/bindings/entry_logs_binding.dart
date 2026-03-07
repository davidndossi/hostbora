import 'package:get/get.dart';

import '../controllers/entry_logs_controller.dart';

class EntryLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntryLogsController>(() => EntryLogsController());
  }
}
