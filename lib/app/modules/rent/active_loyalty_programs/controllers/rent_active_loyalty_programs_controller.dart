import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

class RentActiveLoyaltyProgramsController extends BaseController {
  final platinumEnabled = true.obs;
  final referralEnabled = true.obs;
  final earlyRenewalEnabled = false.obs;

  void onCreateNewOffer() {
    Get.toNamed(Routes.RENT_DEFINE_LOYALTY_OFFERS);
  }

  void onViewAnalytics() {}

  void onEditReferralProgram() {}

  void onOpenMenu() {}

  void onOpenNotifications() {}

  void onOpenProfile() {}
}
