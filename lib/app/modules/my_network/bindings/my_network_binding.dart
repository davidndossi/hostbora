import 'package:get/get.dart';

import '../controllers/my_network_controller.dart';

class MyNetworkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyNetworkController>(() => MyNetworkController());
  }
}
