import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/base/feedback_extensions.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/service/remote_account_sync_service.dart';
import '../../../../data/model/staff_request.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';
import '../utils/rent_staff_pay_format.dart';

/// One row in the rent staff list.
class RentStaffListItem {
  const RentStaffListItem({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.payAmountLabel,
    required this.payDayDisplay,
    required this.paymentType,
    required this.amountValue,
  });

  final String id;
  final String name;
  final String jobTitle;
  final String payAmountLabel;
  final String payDayDisplay;
  final String paymentType;
  final double amountValue;
}

class RentStaffManagementController extends BaseController {
  RentStaffManagementController()
    : _local = Get.find<RentStaffLocalDataSource>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentStaffLocalDataSource _local;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final formKey = GlobalKey<FormState>();

  final staff = <RentStaffListItem>[].obs;
  final initialLoad = true.obs;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final payDateController = TextEditingController();

  final paymentType = RentStaffPayFormat.monthly.obs;
  final selectedPrimaryRole = ''.obs;
  final editingStaffId = Rxn<int>();

  String _propertyRef = '';
  String _propertyName = '';

  static const primaryRoleOptions = [
    'Estate Manager',
    'Housekeeping',
    'Security',
    'Gardener',
    'Chef',
    'Receptionist',
    'Maintenance',
    'Other',
  ];

  String get amountFieldLabel {
    switch (paymentType.value) {
      case RentStaffPayFormat.hourly:
        return 'RATE (TSH/HR)';
      case RentStaffPayFormat.perWork:
        return 'RATE (TSH/JOB)';
      default:
        return 'MONTHLY SALARY (TSH)';
    }
  }

  String get amountHint {
    switch (paymentType.value) {
      case RentStaffPayFormat.hourly:
        return 'e.g. 5,000';
      case RentStaffPayFormat.perWork:
        return 'e.g. 50,000';
      default:
        return '450,000';
    }
  }

  /// Sum of monthly contracts only (excludes hourly / per-job rates).
  double get totalMonthlySalaryPool {
    return staff
        .where((s) => s.paymentType == RentStaffPayFormat.monthly)
        .fold(0.0, (a, b) => a + b.amountValue);
  }

  int get monthlyContractCount =>
      staff.where((s) => s.paymentType == RentStaffPayFormat.monthly).length;

  bool get isEditMode => editingStaffId.value != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['staffId'] != null) {
        final id = int.tryParse('${args['staffId']}');
        if (id != null) editingStaffId.value = id;
      }
      _propertyRef = (args['property_ref'] ??
              args['propertyRef'] ??
              args['property_id'] ??
              '')
          .toString()
          .trim();
      _propertyName = (args['property_name'] ??
              args['propertyName'] ??
              args['property'] ??
              '')
          .toString()
          .trim();
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadStaff().then((_) => _prefillIfEditing());
  }

  Future<void> loadStaff() async {
    try {
      if (Get.isRegistered<RemoteAccountSyncService>()) {
        await Get.find<RemoteAccountSyncService>().syncStaffFromRemote();
      }
      final rows = await _local.getAllNewestFirst();
      staff.assignAll(
        rows.map(
          (r) => RentStaffListItem(
            id: '${r.id}',
            name: r.name,
            jobTitle: r.jobTitle,
            payAmountLabel: r.displayAmountLine,
            payDayDisplay: r.payDayLabel.trim().isEmpty
                ? ''
                : RentStaffPayFormat.payDayLine(r.payDayLabel.trim()),
            paymentType: r.paymentType,
            amountValue: r.amountValue,
          ),
        ),
      );
    } catch (e, st) {
      logger.e('loadStaff $e $st');
      Get.snackbar('Error', 'Could not load staff');
    } finally {
      initialLoad.value = false;
    }
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String? validateFullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter full name';
    if (v.length < 3) return 'Name is too short';
    return null;
  }

  String? validateAmount(String? value) {
    final parsed = _parseAmount(value ?? '');
    if (parsed == null || parsed <= 0) return 'Please enter a valid amount';
    return null;
  }

  String? validatePayDate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter payment date';
    final day = int.tryParse(v);
    if (day == null || day < 1 || day > 31) {
      return 'Use a day between 1 and 31';
    }
    return null;
  }

  void updatePaymentType(String? value) {
    if (value != null && value.isNotEmpty) {
      paymentType.value = value;
    }
  }

  void updatePrimaryRole(String? value) {
    if (value != null && value.isNotEmpty) {
      selectedPrimaryRole.value = value;
    }
  }

  Future<void> _prefillIfEditing() async {
    final id = editingStaffId.value;
    if (id == null) return;
    final record = await _local.getById(id);
    if (record == null) return;
    fullNameController.text = record.name;
    selectedPrimaryRole.value = record.jobTitle;
    payDateController.text = record.payDayLabel;
    paymentType.value = record.paymentType;
    if (record.amountValue > 0) {
      amountController.text = record.amountValue.toStringAsFixed(
        record.amountValue.truncateToDouble() == record.amountValue ? 0 : 2,
      );
    } else if (record.payAmountLabel.isNotEmpty) {
      amountController.text = record.payAmountLabel;
    }
  }

  Future<String> _apiStaffId(int localId) async {
    return await _local.backendIdForLocal(localId) ?? '$localId';
  }

  String? _backendIdFromResponse(dynamic data) {
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map) {
        return (nested['id'] ?? nested['staffId'])?.toString();
      }
      return (data['id'] ?? data['staffId'])?.toString();
    }
    return null;
  }

  StaffRequest _buildStaffRequest({
    required String name,
    required String role,
    required double amount,
    required String payDay,
    String? id,
    String? startDate,
  }) {
    return StaffRequest(
      id: id,
      name: name,
      role: role,
      salary: amount,
      salaryFrequency: paymentType.value,
      phone: phoneController.text.trim(),
      notes: notesController.text.trim(),
      propertyName: _propertyName,
      propertyRef: _propertyRef,
      startDate: startDate,
      status: 'active',
      payDayLabel: payDay,
    );
  }

  Future<void> registerStaff() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final name = fullNameController.text.trim();
    final payDay = payDateController.text.trim();
    final role = selectedPrimaryRole.value.trim();
    final amount = _parseAmount(amountController.text);

    if (role.isEmpty) {
      Get.snackbar('Error', 'Please select a primary role');
      return;
    }
    if (amount == null) return;

    await runBusy(() async {
      try {
        final editId = editingStaffId.value;
        if (editId != null) {
          await _local.updateById(
            id: editId,
            name: name,
            jobTitle: role,
            payDayLabel: payDay,
            paymentType: paymentType.value,
            amountValue: amount,
          );
          final request = _buildStaffRequest(
            name: name,
            role: role,
            amount: amount,
            payDay: payDay,
            id: '$editId',
          );
          final apiStaffId = await _apiStaffId(editId);
          try {
            final res =
                await _repository.updateStaff(apiStaffId, request.toApiJson());
            if (!res.isSuccess) throw Exception(res.message ?? 'API error');
          } catch (_) {
            final payload = request.toApiJson()..['id'] = apiStaffId;
            await _syncQueue.enqueue(
              entityType: 'staff',
              operation: 'update',
              payloadJson: jsonEncode(payload),
              dedupeKey: 'staff:update:$apiStaffId',
            );
            _syncWorker.runNow();
          }
          showSuccessWithHaptic('Staff updated');
          Get.back(result: true);
          return;
        }

        final localId = await _local.insert(
          name: name,
          jobTitle: role,
          payDayLabel: payDay,
          paymentType: paymentType.value,
          amountValue: amount,
        );
        final today = DateTime.now();
        final startDate =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final request = _buildStaffRequest(
          name: name,
          role: role,
          amount: amount,
          payDay: payDay,
          startDate: startDate,
        );
        try {
          final res = await _repository.createStaff(request.toApiJson());
          if (!res.isSuccess) throw Exception(res.message ?? 'API error');
          final backendId = _backendIdFromResponse(res.data);
          if (backendId != null) {
            await _local.saveBackendId(localId, backendId);
          }
        } catch (_) {
          await _syncQueue.enqueue(
            entityType: 'staff',
            operation: 'create',
            payloadJson: jsonEncode(request.toApiJson()),
            dedupeKey: 'staff:create:$localId',
          );
          _syncWorker.runNow();
        }
        formKey.currentState?.reset();
        fullNameController.clear();
        phoneController.clear();
        notesController.clear();
        amountController.clear();
        payDateController.clear();
        selectedPrimaryRole.value = '';
        paymentType.value = RentStaffPayFormat.monthly;
        await loadStaff();
        showSuccessWithHaptic('Staff was added successfully');
      } catch (e, st) {
        logger.e('registerStaff $e $st');
        hapticValidationError();
        Get.snackbar('Error', 'Could not save staff');
      }
    });
  }

  void editStaff(RentStaffListItem member) {
    Get.toNamed(
      Routes.RENT_STAFF_MANAGEMENT,
      arguments: {'staffId': member.id},
    )?.then((_) => loadStaff());
  }

  Future<void> removeStaff(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null) return;
    final snapshot = await _local.getById(parsed);
    if (snapshot == null) return;

    final confirmed = await confirmDestructive(
      title: 'Remove staff member?',
      message: 'Remove ${snapshot.name.trim()} from your team list?',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    await runDestructiveWithUndo(
      message: 'Staff member removed',
      action: () async {
        await _local.deleteById(parsed);
        await loadStaff();
      },
      onUndo: () async {
        await _local.insert(
          name: snapshot.name,
          jobTitle: snapshot.jobTitle,
          payDayLabel: snapshot.payDayLabel,
          paymentType: snapshot.paymentType,
          amountValue: snapshot.amountValue,
        );
        await loadStaff();
      },
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    amountController.dispose();
    payDateController.dispose();
    super.onClose();
  }
}
