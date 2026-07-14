import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/subscription_status.dart';
import '../../../data/service/subscription_service.dart';

class SubscriptionController extends BaseController {
  SubscriptionController()
      : _subscriptionService = Get.find<SubscriptionService>();

  final SubscriptionService _subscriptionService;

  SubscriptionStatus get currentStatus => _subscriptionService.status.value;

  final activatingTrial    = false.obs;
  final startingCheckout   = false.obs;
  final selectedPlan       = 'pro'.obs;

  /// Activate the 30-day free trial (first-time users only).
  Future<void> requestTrial() async {
    activatingTrial.value = true;
    try {
      final ok = await _subscriptionService.activateTrial();
      if (ok) {
        showSuccessMessage('30-day free trial activated! Enjoy HostBora Starter.');
      } else {
        showErrorMessage('Trial is no longer available for this account.');
      }
    } finally {
      activatingTrial.value = false;
    }
  }

  /// Subscribe via App Store (iOS) or Snippe checkout (Android).
  Future<void> subscribe(String plan) async {
    startingCheckout.value = true;
    try {
      if (_subscriptionService.usesAppleIap) {
        final ok = await _subscriptionService.startApplePurchase(plan);
        if (ok) {
          showSuccessMessage('Subscription activated. Thank you!');
        } else {
          showErrorMessage('Purchase was not completed. Please try again.');
        }
        return;
      }

      final checkout = await _subscriptionService.startCheckout(plan);
      if (checkout == null) {
        showErrorMessage('Could not start payment. Please try again.');
      } else {
        showSuccessMessage(
          'Payment page opened. Complete payment in the browser, then return here.',
        );
        // Poll server after a short delay so the UI updates once the webhook fires.
        await Future.delayed(const Duration(seconds: 5));
        await _subscriptionService.refresh();
      }
    } finally {
      startingCheckout.value = false;
    }
  }

  /// Manually refresh subscription state from the server.
  @override
  Future<void> refresh() => _subscriptionService.refresh();

  Future<void> restorePurchases() async {
    if (!_subscriptionService.usesAppleIap) return;
    startingCheckout.value = true;
    try {
      await _subscriptionService.restoreApplePurchases();
      showSuccessMessage('Purchases restored.');
    } finally {
      startingCheckout.value = false;
    }
  }

  String? priceLabel(String planKey) {
    if (_subscriptionService.usesAppleIap) {
      return _subscriptionService.applePriceForPlan(planKey);
    }
    return null;
  }

  bool get usesAppleIap => _subscriptionService.usesAppleIap;

  String planName(String key) {
    switch (key) {
      case 'starter': return 'Starter';
      case 'pro':     return 'Pro';
      case 'ultra':   return 'Ultra';
      default:        return key;
    }
  }

  PlanInfo planInfo(String key) =>
      hostBoraPlanInfos.firstWhere((p) => p.key == key,
          orElse: () => hostBoraPlanInfos.first);
}
