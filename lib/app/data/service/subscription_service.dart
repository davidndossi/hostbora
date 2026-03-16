import '/flavors/build_config.dart';
import 'azampay_service.dart';

/// Subscription product: SMS/WhatsApp monthly plan.
const int subscriptionMonthlyPriceTzs = 15000;

/// Prefix for AzamPay externalId for subscription payments.
const String subscriptionPaymentExternalIdPrefix = 'sms_sub_';

/// Handles subscription payment via AzamPay (https://developerdocs.azampay.co.tz).
/// Sends push-to-pay to the user's phone; after they complete payment, subscription
/// is activated (e.g. from SubscriptionController.activateAfterPayment()).
class SubscriptionService {
  SubscriptionService() : _azamPay = AzamPayService();

  final AzamPayService _azamPay;

  bool get isAzamPayConfigured => BuildConfig.instance.config.isAzamPayConfigured;

  /// Sends a push-to-pay request for one month subscription (15,000 TZS).
  /// [userPhone] – customer phone (e.g. 255712345678 or 0712345678).
  /// [provider] – mobile money provider (e.g. Mpesa, Airtel, Tigo, Halopesa, Azampesa).
  /// Returns the checkout result (success = request sent to user's phone).
  Future<AzamPayCheckoutResult> requestSubscriptionPayment({
    required String userPhone,
    required String provider,
  }) async {
    final externalId =
        '$subscriptionPaymentExternalIdPrefix${DateTime.now().millisecondsSinceEpoch}';
    return _azamPay.sendPushToPay(
      customerPhone: userPhone,
      amount: '$subscriptionMonthlyPriceTzs',
      provider: provider,
      externalId: externalId,
      additionalProperties: <String, dynamic>{
        'description': 'SMS/WhatsApp subscription (30 days)',
      },
    );
  }
}
