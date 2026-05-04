import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/service/azampay_service.dart';
import '../../../data/service/subscription_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionView extends BaseView<SubscriptionController> {
  SubscriptionView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(
        context,
        en: 'SMS / WhatsApp Subscription',
        sw: 'Usajili wa SMS / WhatsApp',
      ),
      isCentered: true,
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainerHigh : null,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppValues.largePadding,
          right: AppValues.largePadding,
          top: AppValues.largePadding,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppValues.largePadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t(context, en: 'Pay with AzamPay', sw: 'Lipa kwa AzamPay'),
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                context,
                en: 'Enter your mobile number and select your mobile money provider. You will receive a payment request on your phone.',
                sw: 'Weka namba yako ya simu na chagua mtoa huduma wa fedha za simu. Utapokea ombi la malipo kwenye simu yako.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppValues.spacing_20),
            TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _t(context, en: 'Phone number', sw: 'Namba ya simu'),
                hintText: _t(
                  context,
                  en: '0712345678',
                  sw: '0712345678',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppValues.padding),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.selectedProvider.value,
                decoration: InputDecoration(
                  labelText: _t(
                    context,
                    en: 'Mobile money provider',
                    sw: 'Mtoa huduma wa fedha za simu',
                  ),
                  border: OutlineInputBorder(),
                ),
                items: azamPayProviders
                    .map(
                      (String p) =>
                          DropdownMenuItem<String>(value: p, child: Text(p)),
                    )
                    .toList(),
                onChanged: controller.setProvider,
              ),
            ),
            const SizedBox(height: AppValues.spacing_20),
            Obx(
              () => SizedBox(
                height: AppValues.formButtonHeight,
                child: ElevatedButton(
                  onPressed: controller.sendingPaymentRequest.value
                      ? null
                      : () async {
                          final ok = await controller.requestPayment();
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                            _showCompletedPaymentDialog(ctx);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                  ),
                  child: controller.sendingPaymentRequest.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _t(
                            context,
                            en: 'Send payment request',
                            sw: 'Tuma ombi la malipo',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletedPaymentDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? theme.colorScheme.surfaceContainerHigh : null,
        title: Text(
          _t(context, en: 'Complete payment', sw: 'Kamilisha malipo'),
        ),
        content: Text(
          _t(
            context,
            en: 'A payment request was sent to your phone. Complete the payment in your mobile money app, then tap below to activate your subscription.',
            sw: 'Ombi la malipo limetumwa kwenye simu yako. Kamilisha malipo kwenye app ya fedha za simu, kisha gusa hapa chini kuanzisha usajili wako.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t(context, en: 'Cancel', sw: 'Ghairi')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.activateAfterPayment();
            },
            child: Text(
              _t(
                context,
                en: "I've completed payment",
                sw: 'Nimekamilisha malipo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priceStr =
        '${subscriptionMonthlyPriceTzs.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TZS';
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppValues.largePadding,
          vertical: AppValues.extraLargePadding,
        ),
        child: Obx(() {
          final isSubscribed = controller.isSubscribed;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppValues.spacing_20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppValues.largePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sms_outlined,
                        size: 48,
                        color: AppColors.colorPrimary,
                      ),
                      const SizedBox(height: AppValues.spacing_20),
                      Text(
                        _t(
                          context,
                          en: 'Send SMS & WhatsApp',
                          sw: 'Tuma SMS na WhatsApp',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : AppColors.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: AppValues.smallPadding),
                      Text(
                        _t(
                          context,
                          en: 'Subscribe to send SMS and use WhatsApp features from the app. Access includes SMS sending and WhatsApp chat/group tools.',
                          sw: 'Jisajili kutuma SMS na kutumia huduma za WhatsApp kupitia app. Ufikiaji unajumuisha kutuma SMS na zana za mazungumzo/vikundi vya WhatsApp.',
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : AppColors.textColorSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppValues.spacing_20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppValues.padding,
                          vertical: AppValues.halfPadding,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.colorPrimaryLight.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppValues.smallRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              priceStr,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _t(context, en: 'per month', sw: 'kwa mwezi'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppValues.spacing_30),
              if (isSubscribed) ...[
                Container(
                  padding: const EdgeInsets.all(AppValues.padding),
                  decoration: BoxDecoration(
                    color: AppColors.colorSuccessGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppValues.smallRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.colorSuccessGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_t(context, en: 'You are subscribed until', sw: 'Usajili wako unaisha')} ${controller.expiryDisplay}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? theme.colorScheme.onSurface : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppValues.spacing_20),
                SizedBox(
                  height: AppValues.formButtonHeight,
                  child: ElevatedButton(
                    onPressed: () => Get.offNamed(Routes.SEND_SMS),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                    ),
                    child: Text(
                      _t(
                        context,
                        en: 'Go to Send SMS / WhatsApp',
                        sw: 'Nenda Kutuma SMS / WhatsApp',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: AppValues.formButtonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (controller.isAzamPayEnabled) {
                        _showPaymentSheet(context);
                      } else {
                        controller.subscribe();
                      }
                    },
                    icon: const Icon(Icons.payment, size: 22),
                    label: Text(
                      '${_t(context, en: 'Subscribe', sw: 'Jisajili')} — $priceStr / ${_t(context, en: 'month', sw: 'mwezi')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppValues.halfPadding),
                Text(
                  controller.isAzamPayEnabled
                      ? _t(
                          context,
                          en: 'Payment via AzamPay (mobile money). Subscription is valid for 30 days.',
                          sw: 'Malipo kupitia AzamPay (fedha za simu). Usajili ni halali kwa siku 30.',
                        )
                      : _t(
                          context,
                          en: 'Payment will be processed as per your operator. Subscription is valid for 30 days.',
                          sw: 'Malipo yatachakatwa kulingana na mtoa huduma wako. Usajili ni halali kwa siku 30.',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : AppColors.textColorSecondary,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
