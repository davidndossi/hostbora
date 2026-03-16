import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/pending_payments_store.dart';
import '../../../data/model/record_payment_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/unauthorize_exception.dart';
import '../../../routes/app_pages.dart';

enum PaymentStatus { paid, pending }

class RecordPaymentController extends BaseController {
  RecordPaymentController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _preferenceManager = Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
        _pendingStore = PendingPaymentsStore();

  final AppRepository _repository;
  final PreferenceManager _preferenceManager;
  final PendingPaymentsStore _pendingStore;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final linkedBookingController = TextEditingController();

  final selectedPaymentMethod = Rx<String>('Cash');
  final paymentDate = Rx<DateTime>(DateTime.now());
  final status = PaymentStatus.paid.obs;
  final saving = false.obs;
  final syncing = false.obs;

  static const _dateFormat = 'MM/dd/yyyy';
  static const _isoDateFormat = 'yyyy-MM-dd';

  final paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Mobile Money', 'Other'];

  String get paymentDateLabel => DateFormat(_dateFormat).format(paymentDate.value);

  void goBack() => Get.back();

  void selectPaymentMethod(String? value) {
    if (value != null) selectedPaymentMethod.value = value;
  }

  Future<void> pickPaymentDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: paymentDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) paymentDate.value = picked;
  }

  void setStatus(PaymentStatus value) {
    status.value = value;
  }

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
          final request = RecordPaymentRequest.fromJson(item);
          final res = await _repository.recordPayment(request);
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
        Get.snackbar('Synced', synced == 1 ? 'Offline payment synced.' : '$synced offline payments synced.');
      }
    } finally {
      syncing.value = false;
    }
  }

  Future<void> recordPayment() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final amountText = amountController.text.trim().replaceFirst(RegExp(r'^(TZS|\$)\s*'), '').trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('Invalid amount', 'Please enter a valid amount');
      return;
    }
    if (saving.value) return;

    final request = RecordPaymentRequest(
      amount: amount,
      paymentMethod: selectedPaymentMethod.value,
      bookingId: linkedBookingController.text.trim().isEmpty
          ? null
          : linkedBookingController.text.trim(),
      paymentDate: DateFormat(_isoDateFormat).format(paymentDate.value),
      status: status.value == PaymentStatus.paid ? 'PAID' : 'PENDING',
    );

    saving.value = true;
    try {
      final online = await _isOnline();
      if (!online) {
        await _pendingStore.add(request.toJson());
        Get.back();
        Get.snackbar(
          'Saved offline',
          'Payment will sync when you\'re back online.',
          duration: const Duration(seconds: 4),
        );
        saving.value = false;
        return;
      }
      await _syncPendingWhenOnline();
      final token = await _preferenceManager.getString(PreferenceManager.keyToken, defaultValue: '');
      if (token.isEmpty) {
        Get.snackbar(
          'Login required',
          'Please log in to record payments.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed(Routes.AUTH);
        saving.value = false;
        return;
      }
      final res = await _repository.recordPayment(request);
      if (res.responseCode == '201' || res.responseCode == '200') {
        Get.back();
        Get.snackbar('Success', 'Payment recorded');
      } else {
        Get.snackbar('Error', res.message ?? 'Could not record payment');
      }
    } on UnauthorizedException catch (_) {
      Get.snackbar(
        'Session expired',
        'Please log in again to record payments.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.AUTH);
    } catch (e) {
      Get.snackbar('Error', 'Failed to record payment: $e');
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    amountController.dispose();
    linkedBookingController.dispose();
    super.onClose();
  }
}
