import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  TextStyle get _bodyStyle => TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.textColorSecondary,
      );

  Widget _descriptionParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppValues.padding),
      child: Text(text, style: _bodyStyle),
    );
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
          const SizedBox(height: AppValues.largePadding),
          _descriptionParagraph(appLocalization.aboutIntro),
          _descriptionParagraph(appLocalization.aboutBnbFeatures),
          _descriptionParagraph(appLocalization.aboutRentFeatures),
          _descriptionParagraph(appLocalization.aboutSharedFeatures),
          const SizedBox(height: AppValues.halfPadding),
          Text(
            appLocalization.version,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.versionLoading.value
                  ? '…'
                  : controller.versionText.value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
