import 'package:get/get.dart';

import '../controllers/guest_history_controller.dart';

class GuestHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuestHistoryController>(GuestHistoryController.new);
  }
}
