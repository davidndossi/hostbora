import 'package:get/get.dart';

/// Helpers for GetX instance lifecycle.
///
/// [Get.isRegistered] is true for [Get.lazyPut] **before** the instance is
/// created. Calling [Get.find] then eagerly constructs the controller and runs
/// `onInit` — often the source of post-login UI freezes.
abstract final class GetxInstanceProbe {
  /// True when [S] is registered **and** already constructed (not merely lazy).
  static bool isAlive<S>({String? tag}) {
    if (!Get.isRegistered<S>(tag: tag)) return false;
    // isPrepared == true means lazy factory exists but instance is not init yet.
    return !Get.isPrepared<S>(tag: tag);
  }
}
