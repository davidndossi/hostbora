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

  TextStyle get _headingStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textColorPrimary,
      );

  TextStyle get _bodyStyle => TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textColorSecondary,
      );

  TextStyle get _metaStyle => TextStyle(
        fontSize: 14,
        color: AppColors.textColorSecondary,
      );

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppValues.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _headingStyle),
          const SizedBox(height: AppValues.halfPadding),
          Text(body, style: _bodyStyle),
        ],
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final l10n = appLocalization;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppValues.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.termsLastUpdated, style: _metaStyle),
          const SizedBox(height: AppValues.padding),
          Text(l10n.termsIntro, style: _bodyStyle),
          const SizedBox(height: AppValues.halfPadding),
          Text(l10n.termsSwHint, style: _metaStyle),
          const SizedBox(height: AppValues.padding),
          _section(l10n.termsSectionAcceptanceTitle, l10n.termsSectionAcceptanceBody),
          _section(l10n.termsSectionServiceTitle, l10n.termsSectionServiceBody),
          _section(l10n.termsSectionAccountsTitle, l10n.termsSectionAccountsBody),
          _section(l10n.termsSectionAcceptableUseTitle, l10n.termsSectionAcceptableUseBody),
          _section(l10n.termsSectionPaymentsTitle, l10n.termsSectionPaymentsBody),
          _section(l10n.termsSectionDataPrivacyTitle, l10n.termsSectionDataPrivacyBody),
          _section(l10n.termsSectionDisclaimersTitle, l10n.termsSectionDisclaimersBody),
          _section(l10n.termsSectionLiabilityTitle, l10n.termsSectionLiabilityBody),
          _section(l10n.termsSectionGoverningLawTitle, l10n.termsSectionGoverningLawBody),
          _section(l10n.termsSectionChangesTitle, l10n.termsSectionChangesBody),
          _section(l10n.termsSectionContactTitle, l10n.termsSectionContactBody),
          const SizedBox(height: AppValues.halfPadding),
        ],
      ),
    );
  }
}
