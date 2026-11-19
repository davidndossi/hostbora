import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentLeaseRenewalFormController extends BaseController
    with RentRealDataControllerMixin {
  RentLeaseRenewalFormController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();

  final tenantNameController = TextEditingController();
  final propertyLineController = TextEditingController();
  final rentAmountController = TextEditingController();
  final notesController = TextEditingController();

  final newLeaseStart = Rxn<DateTime>();
  final newLeaseEnd = Rxn<DateTime>();

  final rentFrequency = 'Monthly'.obs;

  static const frequencyOptions = ['Monthly', 'Quarterly', 'Annually'];

  @override
  void onInit() {
    super.onInit();
    final name = Get.parameters['tenantName']?.trim() ?? '';
    final prop = Get.parameters['property']?.trim() ?? '';
    if (name.isNotEmpty) tenantNameController.text = name;
    if (prop.isNotEmpty) propertyLineController.text = prop;
    // A renewal almost always extends by a year from today; the route carries
    // no current lease end date to offset from.
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    newLeaseStart.value = start;
    newLeaseEnd.value = DateTime(start.year + 1, start.month, start.day);
    unawaited(_seedFromCurrentLease(name: name, propertyLabel: prop));
  }

  /// A renewal carries the existing rent forward unless the host changes it,
  /// so the current figures are the right starting point. Left blank when the
  /// tenant cannot be resolved rather than guessed at.
  Future<void> _seedFromCurrentLease({
    required String name,
    required String propertyLabel,
  }) async {
    if (name.isEmpty || propertyLabel.isEmpty) return;
    if (!Get.isRegistered<TenantLocalDataSource>()) return;
    try {
      final tenant = await Get.find<TenantLocalDataSource>()
          .findByNameAndProperty(tenantName: name, propertyLabel: propertyLabel);
      if (tenant == null) return;

      if (rentAmountController.text.trim().isEmpty &&
          tenant.rentAmountValue > 0) {
        rentAmountController.text = tenant.rentAmountValue.toStringAsFixed(0);
      }
      final matched = _matchFrequency(tenant.rentFrequency);
      if (matched != null) rentFrequency.value = matched;
    } catch (_) {
      // Seeding is a convenience; the form still opens without it.
    }
  }

  /// Maps a stored tenant frequency onto this form's three options. Anything
  /// that does not map — per night, weekly — leaves the default alone, since
  /// this form cannot represent it.
  static String? _matchFrequency(String raw) {
    final f = raw.trim().toLowerCase();
    if (f.contains('month')) return 'Monthly';
    if (f.contains('quarter')) return 'Quarterly';
    if (f.contains('year') || f.contains('annual')) return 'Annually';
    return null;
  }

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }

  void setRentFrequency(String? v) {
    if (v != null && frequencyOptions.contains(v)) {
      rentFrequency.value = v;
    }
  }

  void setNewLeaseRange(DateTimeRange range) {
    newLeaseStart.value = DateTime(range.start.year, range.start.month, range.start.day);
    newLeaseEnd.value = DateTime(range.end.year, range.end.month, range.end.day);
  }

  String? validateTenantName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return Get.locale?.languageCode == 'sw'
          ? 'Jina la mpangaji linahitajika'
          : 'Tenant name is required';
    }
    return null;
  }

  String? validateProperty(String? v) {
    if (v == null || v.trim().isEmpty) {
      return Get.locale?.languageCode == 'sw'
          ? 'Mali au anwani inahitajika'
          : 'Property or address is required';
    }
    return null;
  }

  String? validateRent(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t.replaceAll(',', ''));
    if (n == null || n < 0) {
      return Get.locale?.languageCode == 'sw'
          ? 'Kiasi si halali'
          : 'Enter a valid amount';
    }
    return null;
  }

  bool _datesValid() {
    final s = newLeaseStart.value;
    final e = newLeaseEnd.value;
    return s != null && e != null && !e.isBefore(s);
  }

  Future<void> submitRenewal() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!_datesValid()) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Chagua tarehe za kuanza na kuisha za mkataba mpya.'
            : 'Pick new lease start and end dates.',
      );
      return;
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final payload = <String, dynamic>{
      'tenantName': tenantNameController.text.trim(),
      'propertyLine': propertyLineController.text.trim(),
      'rentAmount': rentAmountController.text.trim().replaceAll(',', ''),
      'rentFrequency': rentFrequency.value,
      'leaseStart': fmt.format(newLeaseStart.value!),
      'leaseEnd': fmt.format(newLeaseEnd.value!),
      'notes': notesController.text.trim(),
    };

    try {
      final res = await _repository.renewLease(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'lease',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey:
            'lease:create:${payload['tenantName']}:${payload['leaseStart']}',
      );
      _syncWorker.runNow();
    }

    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Uhuishaji wa mkataba umehifadhiwa.'
          : 'Lease renewal saved.',
    );
    Get.back(result: true);
  }

  @override
  void onClose() {
    tenantNameController.dispose();
    propertyLineController.dispose();
    rentAmountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
