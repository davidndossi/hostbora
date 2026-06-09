import 'package:get/get.dart';
import '../controllers/all_tenants_controller.dart';

class AllTenantsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllTenantsController>(() => AllTenantsController());
  }
}
