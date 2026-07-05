import 'dart:async';

import 'package:get/get.dart';

import 'remote_account_sync_service.dart';

/// Fire-and-forget account sync after login or app resume.
void triggerRemoteAccountSync() {
  if (!Get.isRegistered<RemoteAccountSyncService>()) return;
  unawaited(Get.find<RemoteAccountSyncService>().syncAll());
}
