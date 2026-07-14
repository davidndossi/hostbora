import 'package:get/get.dart';

import 'dart:io';

import '../data/help/guided_tour_service.dart';
import '../data/service/apple_iap_service.dart';
import '../data/service/subscription_service.dart';
import 'local_source_bindings.dart';
import 'remote_source_bindings.dart';
import 'repository_bindings.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    RepositoryBindings().dependencies();
    RemoteSourceBindings().dependencies();
    LocalSourceBindings().dependencies();
    Get.put<GuidedTourService>(GuidedTourService(), permanent: true);
    if (Platform.isIOS) {
      Get.put<AppleIapService>(AppleIapService(), permanent: true);
    }
    Get.put<SubscriptionService>(SubscriptionService(), permanent: true);
  }
}
