import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
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

  @override
  Widget body(BuildContext context) {
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
                              '15,000 TZS',
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
                    onPressed: () => controller.subscribe(),
                    icon: const Icon(Icons.payment, size: 22),
                    label: const Text(
                      'Subscribe — 15,000 TZS / month',
                      style: TextStyle(
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
                const Text(
                  'Payment will be processed as per your operator. Subscription is valid for 30 days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
