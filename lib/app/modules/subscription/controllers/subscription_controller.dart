import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../routes/app_pages.dart';

/// Subscription expiry key: milliseconds since epoch when subscription ends.
const String keySmsSubscriptionExpiry = 'sms_subscription_expiry';

/// Monthly price in TZS.
const int subscriptionMonthlyPriceTzs = 15000;

/// Duration of one subscription period (30 days in milliseconds).
const int subscriptionPeriodMs = 30 * 24 * 60 * 60 * 1000;

class SubscriptionController extends BaseController {
  final PreferenceManager _preferenceManager =
      Get.find(tag: (PreferenceManager).toString());

  /// Expiry timestamp in ms; 0 means not subscribed.
  final subscriptionExpiryMs = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExpiry();
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

  /// Subscribe for one month (15,000 TZS). In a real app this would call a payment API.
  Future<void> subscribe() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newExpiry = now + subscriptionPeriodMs;
    await _preferenceManager.setInt(keySmsSubscriptionExpiry, newExpiry);
    subscriptionExpiryMs(newExpiry);
    showSuccessMessage('Subscription active. You can now use Send SMS/WhatsApp.');
    // Navigate to Send SMS so user can use the feature.
    Get.offNamed(Routes.SEND_SMS);
  }

  /// Format expiry for display.
  String get expiryDisplay {
    final expiry = subscriptionExpiryMs.value;
    if (expiry <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(expiry);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
