import 'package:get/get.dart';

import '../controllers/rent_concierge_inbox_controller.dart';

class RentConciergeInboxBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<RentConciergeInboxController>(() => RentConciergeInboxController());
}
