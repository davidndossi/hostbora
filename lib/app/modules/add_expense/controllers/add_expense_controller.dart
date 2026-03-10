import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/pending_expenses_store.dart';
import '../../../data/model/add_expense_request.dart';
import '../../../data/repository/app_repository.dart';

class AddExpenseController extends BaseController {
  AddExpenseController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _pendingStore = PendingExpensesStore();

  final AppRepository _repository;
  final PendingExpensesStore _pendingStore;
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final vendorController = TextEditingController();

  final selectedCategory = Rx<String?>(null);
  final taxDeductible = true.obs;
  final selectedDate = Rx<DateTime?>(null);
  final saving = false.obs;
  final syncing = false.obs;
  /// Local file path of captured receipt image (camera).
  final receiptFilePath = Rx<String?>(null);

  static const _isoDateFormat = 'yyyy-MM-dd';

  @override
  void onReady() {
    super.onReady();
    _syncPendingWhenOnline();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        _syncPendingWhenOnline();
      }
    });
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  }

  Future<void> _syncPendingWhenOnline() async {
    if (syncing.value) return;
    if (!await _isOnline()) return;
    final list = _pendingStore.load();
    if (list.isEmpty) return;
    syncing.value = true;
    try {
      final toKeep = <Map<String, dynamic>>[];
      var synced = 0;
      for (final item in list) {
        try {
          final receiptPath = item['receiptFilePath'] as String?;
          if (receiptPath != null && !File(receiptPath).existsSync()) {
            toKeep.add(item);
            continue;
          }
          final request = AddExpenseRequest.fromJson(item);
          final res = await _repository.addExpense(request, receiptPath);
          if (res.responseCode == '200' || res.responseCode == '201') {
            synced++;
          } else {
            toKeep.add(item);
          }
        } catch (_) {
          toKeep.add(item);
        }
      }
      await _pendingStore.save(toKeep);
      if (synced > 0) {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar('Synced', synced == 1 ? 'Offline expense synced.' : '$synced offline expenses synced.');
      }
    } finally {
      syncing.value = false;
    }
  }

  final categories = [
    'Maintenance',
    'Utilities',
    'Staffing',
    'Supplies',
    'Cleaning',
    'Insurance',
    'Repairs',
    'Other',
  ];

  void selectCategory(String? value) {
    selectedCategory.value = value;
  }

  void setTaxDeductible(bool value) {
    taxDeductible.value = value;
  }

  Future<void> pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedDate.value = date;
      dateController.text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> uploadReceipt() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && picked.path.isNotEmpty) {
        receiptFilePath.value = picked.path;
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not capture receipt: $e');
    }
  }

  void clearReceipt() {
    receiptFilePath.value = null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final category = selectedCategory.value;
    final date = selectedDate.value;
    if (category == null || category.isEmpty) {
      Get.snackbar('Error', 'Please select a category');
      return;
    }
    if (date == null) {
      Get.snackbar('Error', 'Please select a date');
      return;
    }
    final amountText = amountController.text
        .trim()
        .replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }
    if (saving.value) return;

    final request = AddExpenseRequest(
      amount: amount,
      category: category,
      expenseDate: DateFormat(_isoDateFormat).format(date),
      vendor: vendorController.text.trim(),
      taxDeductible: taxDeductible.value,
    );

    saving.value = true;
    try {
      final online = await _isOnline();
      if (!online) {
        await _pendingStore.add(request.toJson(), receiptFilePath.value);
        Get.back();
        Get.snackbar(
          'Saved offline',
          'Expense will sync when you\'re back online.',
          duration: const Duration(seconds: 4),
        );
        saving.value = false;
        return;
      }
      await _syncPendingWhenOnline();
      final res = await _repository.addExpense(request, receiptFilePath.value);
      if (res.responseCode == '200' || res.responseCode == '201') {
        Get.back();
        Get.snackbar('Success', res.message ?? 'Expense recorded.');
      } else {
        Get.snackbar('Error', res.message ?? 'Could not add expense.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense. Please try again.');
    } finally {
      saving.value = false;
    }
  }

  String? validateRequired(String? value, [String name = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$name is required';
    return null;
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final n = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    amountController.dispose();
    dateController.dispose();
    vendorController.dispose();
    super.onClose();
  }
}
