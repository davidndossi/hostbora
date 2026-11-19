import 'dart:convert';

import 'package:get/get.dart';

import '../../repository/app_repository.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import 'offline_sync_worker_service.dart';

/// Sends a payment-extended lease end to the remote tenant record.
///
/// If the device is offline, or the tenant has not received a remote id yet,
/// the update is queued and retried with the other sync work.
class TenantLeaseRemoteSync {
  TenantLeaseRemoteSync._();

  static Future<void> push({
    required TenantRecord tenant,
    required String leaseEndIso,
  }) async {
    final end = leaseEndIso.trim();
    if (end.isEmpty || tenant.id <= 0) return;
    if (!Get.isRegistered<OfflineSyncQueueLocalDataSource>() ||
        !Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
      return;
    }
    var current = tenant;
    if (Get.isRegistered<TenantLocalDataSource>()) {
      current =
          await Get.find<TenantLocalDataSource>().findById(tenant.id) ??
              tenant;
    }
    final propertyName = await _displayPropertyName(current);
    final payload = <String, dynamic>{
      'id': current.backendTenantId.trim(),
      'localTenantId': current.id,
      'name': current.tenantName.trim(),
      'phone': current.phoneNumber.trim(),
      'email': current.email.trim(),
      'propertyRef': current.propertyRef.trim(),
      'property_name': propertyName,
      'propertyName': propertyName,
      'unitId': current.apartmentUnitId.trim(),
      'unitName': current.unitLabel.trim(),
      'leaseStart': current.leaseStartIso.trim(),
      'leaseEnd': end,
      'rentAmount': current.rentAmountValue,
      'rentFrequency': current.rentFrequency.trim(),
      'rentCurrency': current.rentCurrency.trim(),
    };
    final backendId = current.backendTenantId.trim();
    if (backendId.isNotEmpty) {
      try {
        final repository = Get.find<AppRepository>(
          tag: (AppRepository).toString(),
        );
        final body = Map<String, dynamic>.from(payload)..remove('localTenantId');
        final res = await repository.updateTenant(backendId, body);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (ok) return;
      } catch (_) {}
    }
    try {
      await Get.find<OfflineSyncQueueLocalDataSource>().enqueue(
        entityType: 'tenant',
        operation: 'update',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'tenant:update:lease:${current.id}',
      );
      if (Get.isRegistered<OfflineSyncWorkerService>()) {
        await Get.find<OfflineSyncWorkerService>().runNow();
      }
    } catch (_) {}
  }
}

Future<String> _displayPropertyName(TenantRecord tenant) async {
  final label = tenant.propertyLabel.trim();
  final ref = tenant.propertyRef.trim();
  final labelIsRef = label.isEmpty ||
      label == ref ||
      label.startsWith('local_') ||
      label.startsWith('legacy_');
  if (!labelIsRef) return label;
  if (ref.isEmpty || !Get.isRegistered<PropertyLocalDataSource>()) return '';
  final property = await Get.find<PropertyLocalDataSource>().findByHubId(ref);
  if (property == null) return '';
  final name = property.propertyName.trim();
  if (name.isNotEmpty) return name;
  return property.propertyLocation.trim();
}
