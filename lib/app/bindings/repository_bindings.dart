import 'package:get/get.dart';

import '../data/repository/app_repository.dart';
import '../data/repository/app_repository_impl.dart';

class RepositoryBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppRepository>(
      () => AppRepositoryImpl(),
      tag: (AppRepository).toString(),
      fenix: true
    );
  }
}
