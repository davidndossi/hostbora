import 'package:get/get.dart';

import '../controllers/listing_published_controller.dart';

class ListingPublishedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListingPublishedController>(() => ListingPublishedController());
  }
}
