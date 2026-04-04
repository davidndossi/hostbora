import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_staff_local_data_source.dart';
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
  RentStaffManagementController() : _local = Get.find<RentStaffLocalDataSource>();

  final RentStaffLocalDataSource _local;

  final staff = <RentStaffListItem>[].obs;
  final initialLoad = true.obs;

  final fullNameController = TextEditingController();
  final amountController = TextEditingController();
  final payDateController = TextEditingController();

  final paymentType = RentStaffPayFormat.monthly.obs;
  final selectedPrimaryRole = ''.obs;

  static const primaryRoleOptions = [
    'Estate Manager',
    'Housekeeper',
    'Security',
    'Gardener',
    'Chef',
    'Concierge',
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

  @override
  void onReady() {
    super.onReady();
    loadStaff();
  }

  Future<void> loadStaff() async {
    try {
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

  Future<void> registerStaff() async {
    final name = fullNameController.text.trim();
    final payDay = payDateController.text.trim();
    final role = selectedPrimaryRole.value.trim();
    final amount = _parseAmount(amountController.text);

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter full name');
      return;
    }
    if (role.isEmpty) {
      Get.snackbar('Error', 'Please select a primary role');
      return;
    }
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }
    if (payDay.isEmpty) {
      Get.snackbar('Error', 'Please enter payment date');
      return;
    }

    showLoading();
    try {
      await _local.insert(
        name: name,
        jobTitle: role,
        payDayLabel: payDay,
        paymentType: paymentType.value,
        amountValue: amount,
      );
      fullNameController.clear();
      amountController.clear();
      payDateController.clear();
      selectedPrimaryRole.value = '';
      paymentType.value = RentStaffPayFormat.monthly;
      await loadStaff();
      showSuccessMessage('Staff registered');
    } catch (e, st) {
      logger.e('registerStaff $e $st');
      Get.snackbar('Error', 'Could not save staff');
    } finally {
      hideLoading();
    }
  }

  void editStaff(RentStaffListItem member) {
    Get.snackbar('Edit', member.name);
  }

  Future<void> removeStaff(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null) return;
    showLoading();
    try {
      await _local.deleteById(parsed);
      await loadStaff();
    } catch (e, st) {
      logger.e('removeStaff $e $st');
      Get.snackbar('Error', 'Could not remove staff');
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    amountController.dispose();
    payDateController.dispose();
    super.onClose();
  }
}
