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
          Text(l10n.privacyLastUpdated, style: _metaStyle),
          const SizedBox(height: AppValues.padding),
          Text(l10n.privacyIntro, style: _bodyStyle),
          const SizedBox(height: AppValues.halfPadding),
          Text(l10n.privacySwHint, style: _metaStyle),
          const SizedBox(height: AppValues.padding),
          _section(l10n.privacySectionWhoWeAreTitle, l10n.privacySectionWhoWeAreBody),
          _section(l10n.privacySectionCollectTitle, l10n.privacySectionCollectBody),
          _section(l10n.privacySectionUseTitle, l10n.privacySectionUseBody),
          _section(l10n.privacySectionLegalBasisTitle, l10n.privacySectionLegalBasisBody),
          _section(l10n.privacySectionSharingTitle, l10n.privacySectionSharingBody),
          _section(l10n.privacySectionStorageTitle, l10n.privacySectionStorageBody),
          _section(l10n.privacySectionRetentionTitle, l10n.privacySectionRetentionBody),
          _section(l10n.privacySectionRightsTitle, l10n.privacySectionRightsBody),
          _section(l10n.privacySectionChildrenTitle, l10n.privacySectionChildrenBody),
          _section(l10n.privacySectionChangesTitle, l10n.privacySectionChangesBody),
          _section(l10n.privacySectionContactTitle, l10n.privacySectionContactBody),
          const SizedBox(height: AppValues.halfPadding),
        ],
      ),
    );
  }
}
