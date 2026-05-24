import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../listing_details/models/listing_activity_vm.dart';
import '../../listing_details/services/rent_listing_activity_loader.dart';

class RentListingActivityLogController extends BaseController {
  RentListingActivityLogController()
      : _loader = RentListingActivityLoader();

  final RentListingActivityLoader _loader;
  late final RentListingActivityScope scope = RentListingActivityScope.fromRoute();

  final activities = <ListingActivityVm>[].obs;
  final loading = true.obs;

  String get screenTitle {
    final name = scope.propertyName.trim();
    if (name.isEmpty) return appLocalization.rentListingActivityLogTitle;
    return name;
  }

  @override
  void onReady() {
    super.onReady();
    loadActivities();
  }

  Future<void> loadActivities() async {
    loading.value = true;
    try {
      activities.assignAll(await _loader.load(scope: scope));
    } finally {
      loading.value = false;
    }
  }

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<RentListingActivityLogController>()) return;
    await Get.find<RentListingActivityLogController>().loadActivities();
  }
}
