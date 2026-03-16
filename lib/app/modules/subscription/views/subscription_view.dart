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

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: 'SMS / WhatsApp Subscription',
      isCentered: true,
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
              'Pay with AzamPay',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your mobile number and select your mobile money provider. '
              'You will receive a payment request on your phone.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
              ),
            ),
            const SizedBox(height: AppValues.spacing_20),
            TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0712 345 678 or 255712345678',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppValues.padding),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedProvider.value,
                  decoration: const InputDecoration(
                    labelText: 'Mobile money provider',
                    border: OutlineInputBorder(),
                  ),
                  items: azamPayProviders
                      .map((String p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(p),
                          ))
                      .toList(),
                  onChanged: controller.setProvider,
                )),
            const SizedBox(height: AppValues.spacing_20),
            Obx(() => SizedBox(
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
                        : const Text(
                            'Send payment request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showCompletedPaymentDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete payment'),
        content: const Text(
          'A payment request was sent to your phone. '
          'Complete the payment in your mobile money app, then tap below to activate your subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.activateAfterPayment();
            },
            child: const Text("I've completed payment"),
          ),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final priceStr = '${subscriptionMonthlyPriceTzs.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} TZS';
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
                        'Send SMS & WhatsApp',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColorPrimary,
                            ),
                      ),
                      const SizedBox(height: AppValues.smallPadding),
                      const Text(
                        'Subscribe to send SMS and use WhatsApp features from the app. '
                        'Access includes SMS sending and WhatsApp chat/group tools.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textColorSecondary,
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
                          color: AppColors.colorPrimaryLight.withOpacity(0.6),
                          borderRadius:
                              BorderRadius.circular(AppValues.smallRadius),
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
                            const Text(
                              'per month',
                              style: TextStyle(
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
                    color: AppColors.colorSuccessGreen.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppValues.smallRadius),
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
                          'You are subscribed until ${controller.expiryDisplay}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
                    child: const Text(
                      'Go to Send SMS / WhatsApp',
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
                      'Subscribe — $priceStr / month',
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
                      ? 'Payment via AzamPay (mobile money). Subscription is valid for 30 days.'
                      : 'Payment will be processed as per your operator. Subscription is valid for 30 days.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
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
