import 'dart:async';

import 'package:get/get.dart';

import 'remote_account_sync_service.dart';

/// Fire-and-forget background sync after login (or Main shell open).
///
/// Reconciles properties and tenants both ways: remote → local upsert, and
/// local-only rows → remote create (queued offline if the network call fails).
void triggerRemoteAccountSync() {
  if (!Get.isRegistered<RemoteAccountSyncService>()) return;
  unawaited(Get.find<RemoteAccountSyncService>().syncAll());
}
