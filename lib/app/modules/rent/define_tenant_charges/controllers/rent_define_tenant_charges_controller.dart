import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_tenant_charge_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';

class TenantChargeEntry {
  TenantChargeEntry({
    required this.id,
    required this.chargeType,
    required this.amountTsh,
    required this.description,
  });

  final String id;
  final String chargeType;
  final double amountTsh;
  final String description;

  String get amountFormatted =>
      Get.find<CurrencyService>().formatBase(amountTsh.round());

  String get subtitleLine {
    final t = description.trim();
    if (t.isEmpty) return '';
    return t.length > 90 ? '${t.substring(0, 87)}…' : t;
  }
}

class RentDefineTenantChargesController extends BaseController {
  RentDefineTenantChargesController()
      : _local = Get.find<RentTenantChargeLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentTenantChargeLocalDataSource _local;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final selectedChargeType = 'Security Deposit'.obs;

  static const chargeTypeOptions = [
    'Security Deposit',
    'Service Charge',
    'Cleaning Fee',
    'Utility Deposit',
    'Admin Fee',
    'Other',
  ];

  /// Property context (would come from route / selection).
  final selectedPropertyTitle = ''.obs;

  final charges = <TenantChargeEntry>[].obs;

  double get totalTsh =>
      charges.fold(0.0, (a, b) => a + b.amountTsh);

  String get totalFormatted =>
      Get.find<CurrencyService>().formatBase(totalTsh.round());

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void updateChargeType(String? v) {
    if (v != null && v.isNotEmpty) selectedChargeType.value = v;
  }

  Future<void> submitCharge({required bool addAnother}) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final amount = _parseAmount(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Enter a valid amount');
      return;
    }
    final desc = descriptionController.text.trim();
    if (desc.isEmpty) {
      Get.snackbar('Error', 'Enter description & terms');
      return;
    }

    final localId = await _local.insert(
      propertyLabel: selectedPropertyTitle.value,
      chargeType: selectedChargeType.value,
      amountTsh: amount,
      description: desc,
    );

    final payload = <String, dynamic>{
      'propertyLabel': selectedPropertyTitle.value,
      'chargeType': selectedChargeType.value,
      'amountTsh': amount,
      'description': desc,
    };
    try {
      final res = await _repository.createTenantCharge(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'tenant_charge',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'tenant_charge:create:$localId',
      );
      _syncWorker.runNow();
    }

    charges.add(
      TenantChargeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chargeType: selectedChargeType.value,
        amountTsh: amount,
        description: desc,
      ),
    );
    amountController.clear();
    descriptionController.clear();
    if (addAnother) {
      showSuccessMessage('Charge saved offline — add another');
    } else {
      showSuccessMessage('Charge saved offline');
    }
  }

  String? validateAmount(String? value) {
    final amount = _parseAmount((value ?? '').trim());
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validateDescription(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Description is required';
    if (v.length < 8) return 'Add more detail';
    return null;
  }

  (Color bg, Color iconColor, IconData icon) styleForChargeType(String type) {
    switch (type) {
      case 'Security Deposit':
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.shield_outlined);
      case 'Service Charge':
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20), Icons.home_repair_service_outlined);
      case 'Cleaning Fee':
        return (const Color(0xFFFFE8DC), const Color(0xFFC05020), Icons.cleaning_services_outlined);
      case 'Utility Deposit':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.bolt_outlined);
      case 'Admin Fee':
        return (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A), Icons.description_outlined);
      default:
        return (const Color(0xFFEEEEEE), const Color(0xFF546E7A), Icons.receipt_long_outlined);
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
