import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

enum PaymentStatus { paid, pending }

class RecordPaymentController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final linkedBookingController = TextEditingController();

  final selectedPaymentMethod = Rx<String>('Cash');
  final paymentDate = Rx<DateTime>(DateTime(2023, 10, 27));
  final status = PaymentStatus.paid.obs;

  static const _dateFormat = 'MM/dd/yyyy';

  final paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Mobile Money', 'Other'];

  String get paymentDateLabel => DateFormat(_dateFormat).format(paymentDate.value);

  void goBack() => Get.back();

  void openMoreOptions() {
    // TODO: show menu
  }

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

  void recordPayment() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final amountText = amountController.text.trim().replaceFirst(r'$', '').trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('Invalid amount', 'Please enter a valid amount');
      return;
    }
    // TODO: persist payment and navigate
    Get.back();
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        Get.offAllNamed(Routes.ADD_NEW_BOOKING);
        break; // Bookings - navigate to add booking for now
      case 2:
        break; // Payments - current screen
      case 3:
        Get.offAllNamed(Routes.SETTINGS);
        break; // Profile
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    linkedBookingController.dispose();
    super.onClose();
  }
}
