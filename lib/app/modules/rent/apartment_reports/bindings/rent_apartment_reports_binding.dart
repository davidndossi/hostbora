import 'package:get/get.dart';

import '../controllers/rent_apartment_reports_controller.dart';

class RentApartmentReportsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentApartmentReportsController>(
        () => RentApartmentReportsController(),
      );
}
