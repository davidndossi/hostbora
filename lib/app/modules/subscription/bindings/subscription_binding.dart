import 'package:get/get.dart';

import '../../../data/service/subscription_service.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionService>(() => SubscriptionService());
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
    );
  }
}
