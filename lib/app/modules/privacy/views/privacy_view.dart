import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/privacy_controller.dart';

class PrivacyView extends BaseView<PrivacyController> {
  PrivacyView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: appLocalization.privacyPolicy, isCentered: true);
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppValues.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppValues.halfPadding),
          Text(
            appLocalization.privacyPolicy,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: AppValues.halfPadding),
          Text(
            'Last updated: 2025\n\n'
            'Paa Yangu respects your privacy. We collect only what is needed to provide the service: account information, community membership, and usage necessary for features like notifications.\n\n'
            'Your data is used to run the app and improve your experience. We do not sell your personal information. You can manage notification and privacy choices in Settings.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
