import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/config/subscription_payment_config.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/subscription_status.dart';
import '../../../data/service/subscription_service.dart';
import '../../../routes/app_pages.dart';

class SubscriptionController extends BaseController {
  SubscriptionController()
      : _subscriptionService = Get.find<SubscriptionService>();

  final SubscriptionService _subscriptionService;

  SubscriptionStatus get currentStatus => _subscriptionService.status.value;

  final activatingTrial    = false.obs;
  final startingCheckout   = false.obs;
  final selectedPlan       = 'pro'.obs;
  final blockedForManager  = false.obs;

  @override
  void onInit() {
    super.onInit();
    _guardManagers();
  }

  Future<void> _guardManagers() async {
    try {
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      final isManager = await prefs.getBool(
        PreferenceManager.keyIsPortfolioManager,
        defaultValue: false,
      );
      if (isManager) {
        blockedForManager.value = true;
        showErrorMessage(
          Get.locale?.languageCode == 'sw'
              ? 'Wasimamizi hawawezi kufikia bili au mipango.'
              : 'Managers cannot access billing or plans.',
        );
        Future.microtask(() {
          if (Get.key.currentState?.canPop() == true) Get.back();
        });
      }
    } catch (_) {}
  }

  /// Opens the public Terms of Use (EULA) page used for App Store metadata.
  Future<void> openTermsOfUse() => _openLegalUrl(
        HostBoraLegalUrls.termsOfUse,
        fallbackRoute: Routes.TERMS,
      );

  /// Opens the public Privacy Policy page used for App Store metadata.
  Future<void> openPrivacyPolicy() => _openLegalUrl(
        HostBoraLegalUrls.privacyPolicy,
        fallbackRoute: Routes.PRIVACY,
      );

  Future<void> _openLegalUrl(
    String url, {
    required String fallbackRoute,
  }) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    await Get.toNamed(fallbackRoute);
  }

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
        final result = await _subscriptionService.startApplePurchase(plan);
        if (result.success) {
          showSuccessMessage(
            Get.locale?.languageCode == 'sw'
                ? 'Usajili umewezeshwa. Asante!'
                : 'Subscription activated. Thank you!',
          );
        } else if (result.canceled) {
          showErrorMessage(
            Get.locale?.languageCode == 'sw'
                ? 'Ununuzi umeghairiwa.'
                : 'Purchase canceled.',
          );
        } else {
          final detail = (result.message ?? '').trim();
          showErrorMessage(
            detail.isNotEmpty
                ? detail
                : (Get.locale?.languageCode == 'sw'
                    ? 'Ununuzi haukukamilika. Jaribu tena.'
                    : 'Purchase was not completed. Please try again.'),
          );
        }
        return;
      }

      final result = await _subscriptionService.startCheckout(plan);
      if (!result.opened) {
        final detail = (result.message ?? '').trim();
        showErrorMessage(
          detail.isNotEmpty
              ? detail
              : (Get.locale?.languageCode == 'sw'
                  ? 'Imeshindikana kuanza malipo. Jaribu tena.'
                  : 'Could not start payment. Please try again.'),
        );
        return;
      }

      showSuccessMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Ukurasa wa malipo (Snippe) umefunguliwa. Kamilisha malipo kisha rudi kwenye programu.'
            : 'Snippe payment page opened. Complete payment, then return to the app.',
      );

      // Webhook activation can take a few seconds after mobile-money success.
      final activated = await _subscriptionService.waitForPlanActivation(
        plan: plan,
      );
      if (activated) {
        showSuccessMessage(
          Get.locale?.languageCode == 'sw'
              ? 'Mpango umewashwa. Asante!'
              : 'Plan activated. Thank you!',
        );
      } else {
        showErrorMessage(
          Get.locale?.languageCode == 'sw'
              ? 'Malipo yanaweza bado kuchakatwa. Rudi hapa na ubonyeze Subscribe tena au onyesha upya baada ya dakika 1.'
              : 'Payment may still be processing. Return here and tap Subscribe again, or pull to refresh in about a minute.',
        );
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
