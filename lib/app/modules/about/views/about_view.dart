import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/about_controller.dart';

class AboutView extends BaseView<AboutController> {
  AboutView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: appLocalization.about, isCentered: true);
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppValues.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppValues.margin_20),
          Center(
            child: Image.asset(
              'images/paa_yangu_logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
          Center(
            child: Text(
              appLocalization.paaYangu,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppValues.halfPadding),
          Text(
            'Connect with your community. Paa Yangu helps you stay in touch with local groups, get updates, and participate in community life.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
          Text(
            appLocalization.version,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
