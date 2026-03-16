import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/service/azampay_service.dart';
import '../../../data/service/subscription_service.dart';
import '../../../routes/app_pages.dart';

/// Subscription expiry key: milliseconds since epoch when subscription ends.
const String keySmsSubscriptionExpiry = 'sms_subscription_expiry';

/// Duration of one subscription period (30 days in milliseconds).
const int subscriptionPeriodMs = 30 * 24 * 60 * 60 * 1000;

class SubscriptionController extends BaseController {
  SubscriptionController()
      : _preferenceManager =
            Get.find(tag: (PreferenceManager).toString()),
        _subscriptionService = Get.find<SubscriptionService>();

  final PreferenceManager _preferenceManager;
  final SubscriptionService _subscriptionService;

  final phoneController = TextEditingController();
  final selectedProvider = 'Mpesa'.obs;
  final sendingPaymentRequest = false.obs;

  /// Expiry timestamp in ms; 0 means not subscribed.
  final subscriptionExpiryMs = 0.obs;

  bool get isAzamPayEnabled => _subscriptionService.isAzamPayConfigured;

  @override
  void onInit() {
    super.onInit();
    _loadExpiry();
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> _loadExpiry() async {
    final expiry = await _preferenceManager.getInt(
      keySmsSubscriptionExpiry,
      defaultValue: 0,
    );
    subscriptionExpiryMs(expiry);
  }

  /// True if subscription is currently active.
  bool get isSubscribed {
    final expiry = subscriptionExpiryMs.value;
    return expiry > 0 && DateTime.now().millisecondsSinceEpoch < expiry;
  }

  /// Subscribe: if AzamPay is configured, the view should collect phone + provider
  /// and call [requestPayment] then [activateAfterPayment]. If not, activate directly (demo).
  Future<void> subscribe() async {
    if (isAzamPayEnabled) {
      // View shows payment sheet; no direct activation.
      return;
    }
    await activateAfterPayment();
  }

  /// Sends AzamPay push-to-pay for subscription (15,000 TZS). Call after user enters phone + provider.
  Future<bool> requestPayment() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      showErrorMessage('Enter your phone number');
      return false;
    }
    sendingPaymentRequest.value = true;
    try {
      final result = await _subscriptionService.requestSubscriptionPayment(
        userPhone: phone,
        provider: selectedProvider.value,
      );
      if (result.success) {
        showSuccessMessage(
          'Payment request sent to your phone. Complete the payment, then tap "I\'ve completed payment".',
        );
        return true;
      } else {
        showErrorMessage(result.message);
        return false;
      }
    } finally {
      sendingPaymentRequest.value = false;
    }
  }

  /// Activates subscription (30 days). Call after user has completed AzamPay payment.
  Future<void> activateAfterPayment() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newExpiry = now + subscriptionPeriodMs;
    await _preferenceManager.setInt(keySmsSubscriptionExpiry, newExpiry);
    subscriptionExpiryMs(newExpiry);
    showSuccessMessage('Subscription active. You can now use Send SMS/WhatsApp.');
    Get.offNamed(Routes.SEND_SMS);
  }

  void setProvider(String? value) {
    if (value != null) selectedProvider.value = value;
  }

  /// Format expiry for display.
  String get expiryDisplay {
    final expiry = subscriptionExpiryMs.value;
    if (expiry <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(expiry);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
