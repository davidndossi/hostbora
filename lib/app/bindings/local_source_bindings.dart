import 'package:get/get.dart';

import '/app/data/local/db/rent_property_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/preference/preference_manager_impl.dart';

class LocalSourceBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreferenceManager>(
      () => PreferenceManagerImpl(),
      tag: (PreferenceManager).toString(),
      fenix: true,
    );
    Get.lazyPut<RentPropertyLocalDataSource>(
      () => RentPropertyLocalDataSource(),
      fenix: true,
    );
    Get.lazyPut<RentStaffLocalDataSource>(
      () => RentStaffLocalDataSource(),
      fenix: true,
    );
  }
}
