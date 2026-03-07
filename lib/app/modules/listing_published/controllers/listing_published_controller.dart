import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class ListingPublishedController extends BaseController {
  void close() {
    Get.offAllNamed(Routes.MAIN);
  }

  void viewListing() {
    // TODO: navigate to the new listing detail (e.g. with listing id from args)
    Get.offAllNamed(Routes.MAIN);
  }

  void goToDashboard() {
    Get.offAllNamed(Routes.MAIN);
  }
}
