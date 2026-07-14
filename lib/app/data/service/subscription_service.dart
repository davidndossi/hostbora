import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/subscription_payment_config.dart';
import '../model/subscription_status.dart';
import '../repository/app_repository.dart';
import 'apple_iap_service.dart';

/// Plan metadata shown in the UI.
class PlanInfo {
  const PlanInfo({
    required this.key,
    required this.name,
    required this.price,
    required this.tagline,
    required this.features,
    this.isPopular = false,
  });
  final String key;
  final String name;
  final int price; // TZS/month
  final String tagline;
  final List<String> features;
  final bool isPopular;

  String get priceFormatted {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TZS ${buf.toString()}/mo';
  }
}

const List<PlanInfo> hostBoraPlanInfos = [
  PlanInfo(
    key: 'starter',
    name: 'Starter',
    price: 19000,
    tagline: 'For solo hosts getting organised.',
    features: [
      'Up to 3 properties',
      'BnB + Rent workspaces',
      'Payments, expenses & reminders',
      'Basic reports',
    ],
  ),
  PlanInfo(
    key: 'pro',
    name: 'Pro',
    price: 49000,
    tagline: 'For growing portfolios and small teams.',
    features: [
      'Up to 10 properties',
      'Staff, tasks & calendar sync',
      'Document vault & advanced reports',
      'SMS / WhatsApp messaging',
    ],
    isPopular: true,
  ),
  PlanInfo(
    key: 'ultra',
    name: 'Ultra',
    price: 99000,
    tagline: 'For operators and property managers at scale.',
    features: [
      'Unlimited properties',
      'Smart locks & entry logs',
      'AI Manager & design studio',
      'Priority support',
    ],
  ),
];

/// Global subscription state service, registered at app startup.
///
/// Backed by the server — [refresh] calls GET /api/subscription and
/// keeps the reactive [status] up to date. [PlanGate] reads this service
/// to decide whether to allow or block access to a feature.
class SubscriptionService extends GetxService {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  /// Current subscription state. Starts as [SubscriptionStatus.loading] until
  /// the first [refresh] completes.
  final status = Rx<SubscriptionStatus>(SubscriptionStatus.loading);

  bool get isActive        => status.value.isActive;
  bool get isProOrAbove    => isActive && status.value.isProOrAbove;
  bool get isUltra         => isActive && status.value.isUltra;
  bool get hasNoSubscription => status.value.plan == 'none' && status.value.status != 'loading';

  bool get usesAppleIap => SubscriptionPaymentConfig.usesAppleIap;

  AppleIapService? get _appleIap =>
      usesAppleIap && Get.isRegistered<AppleIapService>()
          ? Get.find<AppleIapService>()
          : null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> onInit() async {
    super.onInit();
    await refresh();
  }

  /// Fetches the latest subscription state from the server.
  Future<void> refresh() async {
    try {
      final resp = await _repository.getSubscription();
      if (resp.responseCode == '0') {
        final data = resp.data;
        if (data == null) {
          status.value = SubscriptionStatus(
            id: '', plan: 'none', status: 'none',
          );
        } else {
          status.value = SubscriptionStatus.fromJson(
            Map<String, dynamic>.from(data as Map),
          );
        }
      }
    } catch (_) {
      // Fail silently — keep previous state or loading sentinel.
    }
  }

  // ── Trial ─────────────────────────────────────────────────────────────────

  /// Activates the 30-day free trial. Returns true on success.
  /// The server enforces one-trial-per-account.
  Future<bool> activateTrial() async {
    try {
      final resp = await _repository.activateTrial();
      if (resp.responseCode == '201') {
        await refresh();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Checkout ──────────────────────────────────────────────────────────────

  /// iOS: starts an App Store in-app purchase for [plan].
  Future<bool> startApplePurchase(String plan) async {
    final iap = _appleIap;
    if (iap == null) return false;
    final ok = await iap.purchasePlan(plan);
    if (ok) await refresh();
    return ok;
  }

  /// Restores previous App Store purchases (iOS).
  Future<void> restoreApplePurchases() async {
    final iap = _appleIap;
    if (iap == null) return;
    await iap.restorePurchases();
    await Future.delayed(const Duration(seconds: 3));
    await refresh();
  }

  /// App Store localized price label for [plan], if loaded.
  String? applePriceForPlan(String plan) => _appleIap?.storePriceForPlan(plan);

  /// Android / web: Snippe hosted checkout in the system browser.
  Future<SubscriptionCheckout?> startCheckout(String plan) async {
    try {
      final resp = await _repository.createSubscriptionCheckout(plan);
      if (resp.responseCode == '201' && resp.data != null) {
        final checkout = SubscriptionCheckout.fromJson(
          Map<String, dynamic>.from(resp.data as Map),
        );
        // Open Snippe's hosted checkout page in the system browser.
        // After payment Snippe fires the webhook → server activates subscription.
        final uri = Uri.tryParse(checkout.paymentLinkUrl);
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return checkout;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
