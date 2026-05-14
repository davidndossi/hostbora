import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/terms_controller.dart';

class TermsView extends BaseView<TermsController> {
  TermsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: appLocalization.termsOfService, isCentered: true);
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
            appLocalization.termsOfService,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: AppValues.halfPadding),
          Text(
            'Last updated: 2025\n\n'
            'By using Host Bora you agree to these terms. The app is provided for community engagement and communication. Use it responsibly and in line with your community guidelines.\n\n'
            'We may update these terms from time to time. Continued use of the app after changes means you accept the updated terms.',
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
