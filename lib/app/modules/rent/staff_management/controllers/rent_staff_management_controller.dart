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
import '../utils/rent_staff_pay_format.dart';
import '../widgets/staff_edit_sheet.dart';

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

  /// Used to scroll the registry form into view when Edit is tapped.
  final formSectionKey = GlobalKey();

  bool get _isSw => Get.locale?.languageCode == 'sw';

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
    loadStaff().then((_) async {
      final id = editingStaffId.value;
      if (id != null) {
        // Opened via arguments (e.g. Team & Staff → Edit).
        await editStaffById('$id');
      }
    });
  }

  Future<void> loadStaff() async {
    // Never flip initialLoad back to true — that would tear down the Add Staff
    // form mid-edit when a background refresh runs.
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
      if (initialLoad.value) initialLoad.value = false;
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

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    final normalized = phone
        .replaceAll(RegExp(r'[\s\-]'), '')
        .replaceFirst(RegExp(r'^\+255'), '0')
        .replaceFirst(RegExp(r'^255'), '0');
    final phonePattern = RegExp(r'^0[678]\d{8}$');
    if (!phonePattern.hasMatch(normalized)) {
      return 'Enter a valid phone number (e.g. 0712345678)';
    }
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

  void _clearFormFields() {
    formKey.currentState?.reset();
    fullNameController.clear();
    phoneController.clear();
    notesController.clear();
    amountController.clear();
    payDateController.clear();
    selectedPrimaryRole.value = '';
    paymentType.value = RentStaffPayFormat.monthly;
  }

  void cancelEdit() {
    editingStaffId.value = null;
    _clearFormFields();
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
          editingStaffId.value = null;
          _clearFormFields();
          await loadStaff();
          showSuccessWithHaptic(
            _isSw ? 'Mfanyakazi amesasishwa' : 'Staff updated',
          );
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
        _clearFormFields();
        await loadStaff();
        showSuccessWithHaptic('Staff was added successfully');
      } catch (e, st) {
        logger.e('registerStaff $e $st');
        hapticValidationError();
        Get.snackbar('Error', 'Could not save staff');
      }
    });
  }

  Future<RentStaffRecord?> peekStaffRecord(int id) => _local.getById(id);

  /// Persists edits from [showStaffEditSheet]. Returns false on validation/save error.
  Future<bool> saveStaffEdits({
    required String staffId,
    required String name,
    required String role,
    required String paymentType,
    required String amountRaw,
    required String payDay,
  }) async {
    final editId = int.tryParse(staffId);
    if (editId == null) return false;
    final amount = _parseAmount(amountRaw);
    if (amount == null || amount <= 0) return false;
    if (name.trim().isEmpty || role.trim().isEmpty) return false;

    try {
      await _local.updateById(
        id: editId,
        name: name.trim(),
        jobTitle: role.trim(),
        payDayLabel: payDay.trim(),
        paymentType: paymentType,
        amountValue: amount,
      );
      final request = _buildStaffRequest(
        name: name.trim(),
        role: role.trim(),
        amount: amount,
        payDay: payDay.trim(),
        id: '$editId',
      );
      // Align payment type used in request with the edited value.
      this.paymentType.value = paymentType;
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
      editingStaffId.value = null;
      _clearFormFields();
      await loadStaff();
      showSuccessWithHaptic(
        _isSw ? 'Mfanyakazi amesasishwa' : 'Staff updated',
      );
      return true;
    } catch (e, st) {
      logger.e('saveStaffEdits $e $st');
      Get.snackbar(
        'Error',
        _isSw ? 'Haikuweza kusasisha' : 'Could not update staff',
      );
      return false;
    }
  }

  /// Opens a dedicated edit bottom sheet (visible response to Edit).
  Future<void> editStaff(RentStaffListItem member) async {
    final id = int.tryParse(member.id);
    if (id == null) {
      Get.snackbar(
        'Error',
        _isSw ? 'Mfanyakazi si sahihi' : 'Invalid staff member',
      );
      return;
    }
    editingStaffId.value = id;
    await showStaffEditSheet(controller: this, member: member);
    // If user dismissed without saving, leave the page form clean.
    if (editingStaffId.value != null) {
      editingStaffId.value = null;
    }
  }

  Future<void> editStaffById(String staffId) async {
    final match = staff.firstWhereOrNull((s) => s.id == staffId);
    if (match != null) {
      await editStaff(match);
      return;
    }
    final id = int.tryParse(staffId);
    if (id == null) return;
    final record = await _local.getById(id);
    if (record == null) return;
    await editStaff(
      RentStaffListItem(
        id: '${record.id}',
        name: record.name,
        jobTitle: record.jobTitle,
        payAmountLabel: record.displayAmountLine,
        payDayDisplay: record.payDayLabel.trim().isEmpty
            ? ''
            : RentStaffPayFormat.payDayLine(record.payDayLabel.trim()),
        paymentType: record.paymentType,
        amountValue: record.amountValue,
      ),
    );
  }

  Future<void> removeStaff(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null) return;
    final snapshot = await _local.getById(parsed);
    if (snapshot == null) return;
    final apiStaffId = await _apiStaffId(parsed);

    final confirmed = await confirmDestructive(
      title: 'Remove staff member?',
      message: 'Remove ${snapshot.name.trim()} from your team list?',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    await runDestructiveWithUndo(
      message: 'Staff member removed',
      duration: const Duration(seconds: 4),
      action: () async {
        await _local.deleteById(parsed);
        try {
          final res = await _repository.deleteStaff(apiStaffId);
          if (!res.isSuccess) throw Exception(res.message ?? 'API error');
        } catch (_) {
          await _syncQueue.enqueue(
            entityType: 'staff',
            operation: 'delete',
            payloadJson: jsonEncode({'id': apiStaffId}),
            dedupeKey: 'staff:delete:$apiStaffId',
          );
          _syncWorker.runNow();
        }
        // Refresh from local only so a remote sync cannot rehydrate immediately.
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
