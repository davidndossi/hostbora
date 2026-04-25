import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentListingAnalyticsDashboardController extends BaseController
    with RentRealDataControllerMixin {
  final trendRangeIndex = 0.obs; // 0: daily, 1: weekly, 2: monthly

  String get listingTitleFromRoute =>
      Get.parameters['title']?.trim().isNotEmpty == true
          ? Get.parameters['title']!.trim()
          : 'The Serengeti Vista';

  void setTrendRange(int index) {
    trendRangeIndex.value = index.clamp(0, 2);
  }

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }
}
