import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';


import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/support_controller.dart';

class SupportView extends BaseView<SupportController> {
  SupportView({super.key});

  static const int faqCount = 16;

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
    final cardColor = isDark ? context.tokens.cardBackground : Colors.white;
    final borderColor = isDark ? context.tokens.elevatedSurface : const Color(0xFFE5E7EB);

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
          ...List.generate(faqCount, (i) {
            final index = i + 1;
            return _faqTile(
              context: context,
              title: _faqQuestion(l10n, index),
              body: _faqAnswer(l10n, index),
              cardColor: cardColor,
              borderColor: borderColor,
              bodyColor: bodyColor,
              headingColor: headingColor,
            );
          }),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.sendFeedback, headingColor),
          const SizedBox(height: 10),
          _card(
            color: cardColor,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportFeedbackBody,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.openFeedback,
                  icon: const Icon(Icons.feedback_outlined, size: 20),
                  label: Text(
                    l10n.sendFeedback,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
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
                const SizedBox(height: 8),
                Text(
                  SupportController.supportEmailAddress,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
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

  String _faqQuestion(AppLocalizations l10n, int index) {
    switch (index) {
      case 1:
        return l10n.supportFaq1Q;
      case 2:
        return l10n.supportFaq2Q;
      case 3:
        return l10n.supportFaq3Q;
      case 4:
        return l10n.supportFaq4Q;
      case 5:
        return l10n.supportFaq5Q;
      case 6:
        return l10n.supportFaq6Q;
      case 7:
        return l10n.supportFaq7Q;
      case 8:
        return l10n.supportFaq8Q;
      case 9:
        return l10n.supportFaq9Q;
      case 10:
        return l10n.supportFaq10Q;
      case 11:
        return l10n.supportFaq11Q;
      case 12:
        return l10n.supportFaq12Q;
      case 13:
        return l10n.supportFaq13Q;
      case 14:
        return l10n.supportFaq14Q;
      case 15:
        return l10n.supportFaq15Q;
      case 16:
        return l10n.supportFaq16Q;
      default:
        return '';
    }
  }

  String _faqAnswer(AppLocalizations l10n, int index) {
    switch (index) {
      case 1:
        return l10n.supportFaq1A;
      case 2:
        return l10n.supportFaq2A;
      case 3:
        return l10n.supportFaq3A;
      case 4:
        return l10n.supportFaq4A;
      case 5:
        return l10n.supportFaq5A;
      case 6:
        return l10n.supportFaq6A;
      case 7:
        return l10n.supportFaq7A;
      case 8:
        return l10n.supportFaq8A;
      case 9:
        return l10n.supportFaq9A;
      case 10:
        return l10n.supportFaq10A;
      case 11:
        return l10n.supportFaq11A;
      case 12:
        return l10n.supportFaq12A;
      case 13:
        return l10n.supportFaq13A;
      case 14:
        return l10n.supportFaq14A;
      case 15:
        return l10n.supportFaq15A;
      case 16:
        return l10n.supportFaq16A;
      default:
        return '';
    }
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
