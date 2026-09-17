import 'dart:io';

import 'package:flutter/foundation.dart';

/// Platform-specific subscription billing.
class SubscriptionPaymentConfig {
  SubscriptionPaymentConfig._();

  /// iOS App Store auto-renewable subscriptions (App Store review requirement).
  static bool get usesAppleIap => !kIsWeb && Platform.isIOS;

  /// Android and other platforms use Snippe mobile-money checkout.
  static bool get usesSnippeCheckout => !usesAppleIap;
}

/// Public legal pages — also set these in App Store Connect (Guideline 3.1.2):
/// - App Information → Privacy Policy URL
/// - App Information → License Agreement → Custom EULA (Terms of Use URL)
class HostBoraLegalUrls {
  HostBoraLegalUrls._();

  static const termsOfUse =
      'https://hostbora.co.tz/terms-of-service.html';
  static const privacyPolicy =
      'https://hostbora.co.tz/privacy-policy.html';
}

/// App Store Connect product IDs — must match subscriptions configured there.
class AppleIapProducts {
  AppleIapProducts._();

  static const starter = 'hostbora_starter_monthly';
  static const pro = 'hostbora_pro_monthly';
  static const ultra = 'hostbora_ultra_monthly';

  static const all = {starter, pro, ultra};

  static String productIdForPlan(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'starter':
        return starter;
      case 'pro':
        return pro;
      case 'ultra':
        return ultra;
      default:
        throw ArgumentError('Unknown plan: $plan');
    }
  }

  static String? planForProductId(String productId) {
    switch (productId) {
      case starter:
        return 'starter';
      case pro:
        return 'pro';
      case ultra:
        return 'ultra';
      default:
        return null;
    }
  }
}
