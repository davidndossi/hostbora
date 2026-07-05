import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    // SubscriptionService is a permanent global registered in InitialBinding.
    Get.lazyPut<SubscriptionController>(() => SubscriptionController());
  }
}
