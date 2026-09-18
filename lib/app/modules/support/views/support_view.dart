import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/support_controller.dart';

class SupportView extends BaseView<SupportController> {
  SupportView({super.key});

  static const int faqCount = 16;

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  Color _accent(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return c.isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.colorPrimary;
  }

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
    final c = FormSurfaceColors.of(context);
    final accent = _accent(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(context, l10n, c, accent),
          const SizedBox(height: 16),
          _quickActions(context, l10n, c, accent),
          const SizedBox(height: 16),
          _helpCenterCard(context, c, accent),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportTipsHeading, c.headline),
          const SizedBox(height: 10),
          _tipsGrid(context, c, accent),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportFaqHeading, c.headline),
          const SizedBox(height: 10),
          _faqSearch(context, c),
          const SizedBox(height: 12),
          Obx(() {
            final q = controller.faqQuery.value.trim().toLowerCase();
            final items = <_FaqItem>[];
            for (var i = 1; i <= faqCount; i++) {
              final item = _FaqItem(
                index: i,
                question: _faqQuestion(l10n, i),
                answer: _faqAnswer(l10n, i),
              );
              if (q.isEmpty ||
                  item.question.toLowerCase().contains(q) ||
                  item.answer.toLowerCase().contains(q)) {
                items.add(item);
              }
            }
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _t('No matching questions', 'Hakuna maswali yanayolingana'),
                    style: TextStyle(fontSize: 15, color: c.secondary),
                  ),
                ),
              );
            }
            return Column(
              children: items
                  .map(
                    (item) => _faqTile(
                      context: context,
                      item: item,
                      cardColor: c.card,
                      borderColor: c.border,
                      bodyColor: c.secondary,
                      headingColor: c.headline,
                      accent: accent,
                    ),
                  )
                  .toList(),
            );
          }),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.sendFeedback, c.headline),
          const SizedBox(height: 10),
          _actionCard(
            context: context,
            colors: c,
            icon: Icons.rate_review_outlined,
            iconColor: accent,
            title: l10n.sendFeedback,
            body: l10n.supportFeedbackBody,
            label: l10n.sendFeedback,
            onPressed: controller.openFeedback,
          ),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportContactHeading, c.headline),
          const SizedBox(height: 10),
          _contactCard(context, l10n, c),
          const SizedBox(height: AppValues.largePadding),
          _sectionTitle(l10n.supportLegalHeading, c.headline),
          const SizedBox(height: 10),
          _legalCard(context, l10n, c, accent),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: c.isDark ? c.card : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isDark ? c.border : accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: c.isDark ? 0.22 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded, color: accent, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.supportGetHelpHeading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.headline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportIntro,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: c.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.supportReplySla,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            colors: c,
            accent: accent,
            icon: Icons.email_outlined,
            label: _t('Email', 'Barua pepe'),
            onTap: controller.openSupportEmail,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            colors: c,
            accent: const Color(0xFF25D366),
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            onTap: controller.openWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            colors: c,
            accent: accent,
            icon: Icons.feedback_outlined,
            label: _t('Feedback', 'Maoni'),
            onTap: controller.openFeedback,
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required FormSurfaceColors colors,
    required Color accent,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.headline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpCenterCard(
    BuildContext context,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: controller.openHelpCenter,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Help center', 'Kituo cha msaada'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.headline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'Guides and walkthroughs for every HostBora feature.',
                        'Miongozo ya kila kipengele cha HostBora.',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: c.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.hint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipsGrid(BuildContext context, FormSurfaceColors c, Color accent) {
    final tips = <_TipItem>[
      _TipItem(
        Icons.filter_list_rounded,
        _t('Home filter', 'Kichujio cha Nyumbani'),
        _t(
          'Use All, BnB, or Rent on Home to filter properties. There is no workspace to switch.',
          'Tumia Zote, BnB, au Kodi kwenye Nyumbani kuchuja mali. Hakuna nafasi ya kazi ya kubadilisha.',
        ),
      ),
      _TipItem(
        Icons.sms_outlined,
        _t('Messaging', 'Ujumbe'),
        _t(
          'SMS and WhatsApp need Pro or Ultra. Tap Upgrade to Pro from Home.',
          'SMS na WhatsApp zinahitaji Pro au Ultra. Gonga Boresha hadi Pro kutoka Nyumbani.',
        ),
      ),
      _TipItem(
        Icons.payments_outlined,
        _t('Payments', 'Malipo'),
        _t(
          'Record from Home or a booking. Use See all on Recent payments.',
          'Rekodi kutoka Nyumbani au uhifadhi. Tumia Tazama zote kwenye Malipo ya hivi karibuni.',
        ),
      ),
      _TipItem(
        Icons.handyman_outlined,
        _t('Tasks', 'Kazi'),
        _t(
          'Assign staff from task detail. The assignee stays when you leave.',
          'Wape wafanyakazi kutoka maelezo ya kazi. Mgawo unabaki unapoondoka.',
        ),
      ),
      _TipItem(
        Icons.bar_chart_rounded,
        _t('Reports', 'Ripoti'),
        _t(
          'Open Reports for occupancy, revenue, and expense charts you can export.',
          'Fungua Ripoti kwa chati za utumiaji, mapato, na gharama unazoweza kuhamisha.',
        ),
      ),
      _TipItem(
        Icons.folder_outlined,
        _t('Vault', 'Vault'),
        _t(
          'Store leases and IDs per property. Use search to find a file quickly.',
          'Hifadhi mikataba na vitambulisho kwa mali. Tumia utafutaji kupata faili.',
        ),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tips.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tips.length ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tipTile(c, accent, tips[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < tips.length
                      ? _tipTile(c, accent, tips[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tipTile(FormSurfaceColors c, Color accent, _TipItem tip) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            tip.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.headline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: c.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqSearch(BuildContext context, FormSurfaceColors c) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller.faqSearchController,
      onChanged: (v) => controller.faqQuery.value = v,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: _t('Search questions', 'Tafuta maswali'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(
          () => controller.faqQuery.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: _t('Clear', 'Futa'),
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clearFaqQuery,
                ),
        ),
        filled: true,
        fillColor: c.isDark
            ? theme.colorScheme.surfaceContainerHighest
            : c.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent(context), width: 1.4),
        ),
      ),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required FormSurfaceColors colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.headline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 15)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(
    BuildContext context,
    AppLocalizations l10n,
    FormSurfaceColors c,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supportContactBody,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: c.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.tileBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SupportController.supportEmailAddress,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SupportController.supportWhatsAppDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.openSupportEmail,
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    l10n.supportEmailButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.openWhatsApp,
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(
                    l10n.supportWhatsAppButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legalCard(
    BuildContext context,
    AppLocalizations l10n,
    FormSurfaceColors c,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Text(
              l10n.supportLegalBody,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.secondary,
              ),
            ),
          ),
          _legalTile(
            c,
            accent,
            Icons.description_outlined,
            l10n.supportOpenTerms,
            controller.openTerms,
          ),
          _legalTile(
            c,
            accent,
            Icons.privacy_tip_outlined,
            l10n.supportOpenPrivacy,
            controller.openPrivacy,
          ),
        ],
      ),
    );
  }

  Widget _legalTile(
    FormSurfaceColors c,
    Color accent,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: accent),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: c.headline,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.hint),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.2,
      ),
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
    required _FaqItem item,
    required Color cardColor,
    required Color borderColor,
    required Color bodyColor,
    required Color headingColor,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.index}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            title: Text(
              item.question,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: headingColor,
                height: 1.35,
              ),
            ),
            children: [
              Text(
                item.answer,
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

class _TipItem {
  const _TipItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _FaqItem {
  const _FaqItem({
    required this.index,
    required this.question,
    required this.answer,
  });

  final int index;
  final String question;
  final String answer;
}
