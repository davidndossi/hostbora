import 'package:get/get.dart';

import '../controllers/client_story_controller.dart';

class ClientStoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientStoryController>(() => ClientStoryController());
  }
}
