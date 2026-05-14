import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/support_controller.dart';

class SupportView extends BaseView<SupportController> {
  SupportView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.support,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final l10n = appLocalization;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : AppColors.textColorSecondary;
    final headingColor = isDark ? Colors.white : AppColors.textColorPrimary;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppValues.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppValues.margin_20),
          Text(
            l10n.supportIntro,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportTipsHeading, headingColor),
          const SizedBox(height: 10),
          _card(
            color: cardColor,
            borderColor: borderColor,
            child: Text(
              l10n.supportTipsBody,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: bodyColor,
              ),
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportFaqHeading, headingColor),
          const SizedBox(height: 8),
          _faqTile(
            context: context,
            title: l10n.supportFaq1Q,
            body: l10n.supportFaq1A,
            cardColor: cardColor,
            borderColor: borderColor,
            bodyColor: bodyColor,
            headingColor: headingColor,
          ),
          _faqTile(
            context: context,
            title: l10n.supportFaq2Q,
            body: l10n.supportFaq2A,
            cardColor: cardColor,
            borderColor: borderColor,
            bodyColor: bodyColor,
            headingColor: headingColor,
          ),
          _faqTile(
            context: context,
            title: l10n.supportFaq3Q,
            body: l10n.supportFaq3A,
            cardColor: cardColor,
            borderColor: borderColor,
            bodyColor: bodyColor,
            headingColor: headingColor,
          ),
          _faqTile(
            context: context,
            title: l10n.supportFaq4Q,
            body: l10n.supportFaq4A,
            cardColor: cardColor,
            borderColor: borderColor,
            bodyColor: bodyColor,
            headingColor: headingColor,
          ),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportContactHeading, headingColor),
          const SizedBox(height: 10),
          _card(
            color: cardColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportContactBody,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: controller.openSupportEmail,
                      icon: const Icon(Icons.email_outlined, size: 20),
                      label: Text(l10n.supportEmailButton, style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: controller.openWhatsApp,
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: Text(l10n.supportWhatsAppButton, style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportLegalHeading, headingColor),
          const SizedBox(height: 10),
          _card(
            color: cardColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportLegalBody,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: controller.openTerms,
                      child: Text(l10n.supportOpenTerms),
                    ),
                    TextButton(
                      onPressed: controller.openPrivacy,
                      child: Text(l10n.supportOpenPrivacy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _card({
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _faqTile({
    required BuildContext context,
    required String title,
    required String body,
    required Color cardColor,
    required Color borderColor,
    required Color bodyColor,
    required Color headingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: headingColor,
                height: 1.35,
              ),
            ),
            children: [
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: bodyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
