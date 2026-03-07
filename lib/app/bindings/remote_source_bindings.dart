import 'package:get/get.dart';

import '../data/remote/remote_data_source.dart';
import '../data/remote/remote_data_source_impl.dart';

class RemoteSourceBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemoteDataSource>(
      () => RemoteDataSourceImpl(),
      tag: (RemoteDataSource).toString(),
      fenix: true
    );
  }
}
