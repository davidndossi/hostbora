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

  /// Historical / reported misspellings that must never be sent to StoreKit.
  static const _typoAliases = <String, String>{
    'hostbora_starter_monthly': starter,
    'hostbora_pro_monthly': pro,
    'hostbora_ultra_monthly': ultra,
  };

  /// Maps a raw StoreKit / plan string onto the canonical product ID.
  static String canonicalizeProductId(String productId) {
    final id = productId.trim();
    if (id.isEmpty) return id;
    final lower = id.toLowerCase();
    return _typoAliases[lower] ?? lower.replaceAll('monthalty', 'monthly');
  }

  static String productIdForPlan(String plan) {
    final raw = plan.trim().toLowerCase();
    final canonical = canonicalizeProductId(raw);
    if (planForProductId(canonical) != null) return canonical;

    switch (raw) {
      case 'starter':
      case 'starter_monthly':
        return starter;
      case 'pro':
      case 'pro_monthly':
        return pro;
      case 'ultra':
      case 'ultra_monthly':
        return ultra;
      default:
        throw ArgumentError('Unknown plan: $plan');
    }
  }

  static String? planForProductId(String productId) {
    switch (canonicalizeProductId(productId)) {
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

  static String displayNameForPlan(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'ultra':
        return 'Ultra';
      default:
        return 'selected';
    }
  }
}
