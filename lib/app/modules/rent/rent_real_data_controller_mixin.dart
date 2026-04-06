import 'package:get/get.dart';

import '../../data/local/service/rent_real_data_snapshot_service.dart';

mixin RentRealDataControllerMixin on GetxController {
  final loadingRealData = true.obs;
  final realData = Rxn<RentRealDataSnapshot>();

  Future<void> loadRealDataSnapshot() async {
    loadingRealData.value = true;
    try {
      realData.value = await Get.find<RentRealDataSnapshotService>().load();
    } finally {
      loadingRealData.value = false;
    }
  }
}
