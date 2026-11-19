import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/access/staff_access.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/help/guided_tour_service.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/host_score.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_view.dart';
import '/app/core/widget/custom_app_bar.dart';
import '/app/modules/settings/controllers/settings_controller.dart';

class _P {
  const _P({
    required this.surface,
    required this.canvas,
    required this.ink,
    required this.sub,
    required this.line,
    required this.teal,
    required this.tint,
    required this.score,
    required this.scoreMuted,
    required this.scoreAccent,
    required this.danger,
    required this.dangerTint,
    required this.night,
  });

  final Color surface;
  final Color canvas;
  final Color ink;
  final Color sub;
  final Color line;
  final Color teal;
  final Color tint;
  final Color score;
  final Color scoreMuted;
  final Color scoreAccent;
  final Color danger;
  final Color dangerTint;
  final bool night;

  static _P of(BuildContext context) {
    final tokens = context.tokens;
    final night = Theme.of(context).brightness == Brightness.dark;
    if (night) {
      return _P(
        surface: tokens.cardBackground,
        canvas: tokens.scaffoldBackground,
        ink: tokens.textPrimary,
        sub: tokens.textSecondary,
        line: tokens.border,
        teal: tokens.accent,
        tint: const Color(0xFF233D33),
        score: AppColors.colorPrimaryDark,
        scoreMuted: const Color(0xFFD0E5DB),
        scoreAccent: AppColors.colorPrimaryLight,
        danger: const Color(0xFFE08B84),
        dangerTint: const Color(0x33B05A50),
        night: true,
      );
    }
    return _P(
      surface: tokens.cardBackground,
      canvas: AppColors.pageBackground,
      ink: const Color(0xFF233D38),
      sub: tokens.textSecondary,
      line: tokens.border,
      teal: AppColors.colorPrimary,
      tint: const Color(0xFFEDF5F1),
      score: AppColors.colorPrimary,
      scoreMuted: const Color(0xFFD0E5DB),
      scoreAccent: AppColors.colorPrimaryLight,
      danger: const Color(0xFFB05A50),
      dangerTint: const Color(0x1AB05A50),
      night: false,
    );
  }
}

class SettingsView extends BaseView<SettingsController> {
  SettingsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  String _accountValue(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return _t(context, 'Not provided', 'Haijawekwa');
  }

  @override
  Color pageBackgroundColor(BuildContext context) => _P.of(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final p = _P.of(context);
    return CustomAppBar(
      appBarTitleText: appLocalization.settings,
      isCentered: true,
      backgroundColor: p.canvas,
    );
  }

  @override
  Widget body(BuildContext context) {
    final p = _P.of(context);
    return Obx(() {
      final isAdmin = controller.isAdmin.value;
      final isSales = controller.isSalesAgent.value;
      final isDark = Get.isRegistered<ThemeController>()
          ? Get.find<ThemeController>().isDarkMode.value
          : p.night;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text(
            _t(context, 'Make yourself at home.', 'Jisikie uko nyumbani.'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.6,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              context,
              'Your preferences, your business. All in one thoughtful space.',
              'Mapendeleo yako, biashara yako. Mahali pamoja pazuri.',
            ),
            style: TextStyle(fontSize: 14, height: 1.45, color: p.sub),
          ),
          const SizedBox(height: 22),
          _hostScoreCard(context, p),
          const SizedBox(height: 28),
          _group(
            p,
            title: _t(context, 'ACCOUNT', 'AKAUNTI'),
            children: [
              _row(
                p,
                icon: Icons.person_outline,
                title: _t(context, 'Name', 'Jina'),
                subtitle: _accountValue(context, controller.accountName.value),
              ),
              _row(
                p,
                icon: Icons.email_outlined,
                title: _t(context, 'Email', 'Barua pepe'),
                subtitle: _accountValue(context, controller.accountEmail.value),
              ),
              _row(
                p,
                icon: Icons.phone_outlined,
                title: _t(context, 'Phone number', 'Namba ya simu'),
                subtitle: _accountValue(context, controller.accountPhone.value),
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'PREFERENCES & SECURITY', 'MAPENDELEO NA USALAMA'),
            children: [
              _row(
                p,
                icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: _t(context, 'Appearance', 'Muonekano'),
                subtitle: _t(
                  context,
                  'A look that feels like you',
                  'Muonekano unaokufaa',
                ),
                trailing: _ThemeSwitch(on: isDark, color: p.teal, offColor: p.line),
                onTap: controller.toggleTheme,
              ),
              _row(
                p,
                icon: Icons.language,
                title: _t(context, 'Language', 'Lugha'),
                subtitle: _t(
                  context,
                  'Make yourself at home',
                  'Jisikie uko nyumbani',
                ),
                value: controller.language.value == 'en'
                    ? appLocalization.english
                    : appLocalization.swahili,
                onTap: controller.setDefaultLocale,
              ),
              _row(
                p,
                icon: Icons.payments_outlined,
                title: _t(context, 'Base currency', 'Sarafu ya msingi'),
                subtitle: _t(
                  context,
                  'Used for reports and dashboards',
                  'Inatumika kwenye ripoti na dashibodi',
                ),
                value: Get.isRegistered<CurrencyService>()
                    ? Get.find<CurrencyService>().baseCurrency.value
                    : '',
                onTap: () => controller.showBaseCurrencyPicker(context),
              ),
              _row(
                p,
                icon: Icons.currency_exchange,
                title: _t(
                  context,
                  'Refresh exchange rates',
                  'Sasisha viwango vya ubadilishaji',
                ),
                subtitle: _t(
                  context,
                  'Update TZS conversion rates',
                  'Sasisha viwango vya kubadilisha TZS',
                ),
                onTap: controller.refreshExchangeRates,
              ),
              _row(
                p,
                icon: Icons.security,
                title: appLocalization.security,
                subtitle: appLocalization.securityDescription,
                onTap: () => Get.toNamed(Routes.SECURITY),
              ),
              _row(
                p,
                icon: Icons.timer_outlined,
                title: _t(context, 'App lock timeout', 'Muda wa kufunga app'),
                subtitle: _t(
                  context,
                  'Show welcome screen after the app stays in the background',
                  'Onyesha skrini ya karibu baada ya app kukaa nyuma',
                ),
                value: controller.appLockTimeoutLabel(
                  controller.appLockTimeoutSeconds.value,
                ),
                onTap: () => _showAppLockTimeoutPicker(context),
              ),
              _row(
                p,
                icon: Icons.pin_outlined,
                title: appLocalization.changePinTitle,
                subtitle: _t(
                  context,
                  'Keep your account safe with a 4-digit PIN',
                  'Linda akaunti yako kwa PIN ya tarakimu 4',
                ),
                onTap: controller.openPinSettings,
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'YOUR BUSINESS', 'BIASHARA YAKO'),
            children: [
              if (isSales)
                _row(
                  p,
                  icon: Icons.insights_outlined,
                  title: _t(context, 'My sales dashboard', 'Dashibodi yangu ya mauzo'),
                  subtitle: _t(
                    context,
                    'Recruits, subscribers & commissions',
                    'Waliowajiliwa, wanachama na kamisheni',
                  ),
                  onTap: controller.openSalesAgentDashboard,
                ),
              if (isAdmin)
                _row(
                  p,
                  icon: Icons.groups_outlined,
                  title: _t(context, 'Sales agents', 'Wakala wa mauzo'),
                  subtitle: _t(
                    context,
                    'Manage your team and their progress',
                    'Simamia timu yako na maendeleo yao',
                  ),
                  badge: _t(context, 'Admin', 'Msimamizi'),
                  onTap: controller.openAdminSalesAgents,
                ),
              if (isAdmin)
                _row(
                  p,
                  icon: Icons.trending_up_outlined,
                  title: _t(
                    context,
                    'Growth metrics',
                    'Vipimo vya ukuaji',
                  ),
                  subtitle: _t(
                    context,
                    'Community, registrations, property, retention, referrals',
                    'Jamii, usajili, mali, kurudi, mrejeleo',
                  ),
                  badge: _t(context, 'Admin', 'Msimamizi'),
                  onTap: controller.openAdminGrowthMetrics,
                ),
              if (isAdmin)
                _row(
                  p,
                  icon: Icons.admin_panel_settings_outlined,
                  title: _t(
                    context,
                    'WhatsApp credentials',
                    'Vitambulisho vya WhatsApp',
                  ),
                  subtitle: _t(
                    context,
                    'Per-host Business API status',
                    'Hali ya API kwa kila mwenye nyumba',
                  ),
                  badge: _t(context, 'Admin', 'Msimamizi'),
                  onTap: controller.openAdminWhatsAppCredentials,
                ),
              _row(
                p,
                icon: Icons.hub_outlined,
                title: _t(context, 'My Network', 'Mtandao wangu'),
                subtitle: _t(
                  context,
                  'Invites, active hosts, and HB Points',
                  'Mialiko, wenyeji hai, na HB Points',
                ),
                onTap: () => Get.toNamed(Routes.MY_NETWORK),
              ),
              _row(
                p,
                icon: Icons.manage_accounts_outlined,
                title: _t(context, 'Property Managers', 'Wasimamizi wa Mali'),
                subtitle: _t(
                  context,
                  'Find a HostBora Certified property manager',
                  'Tafuta msimamizi wa mali aliyeidhinishwa na HostBora',
                ),
                onTap: () => Get.toNamed(Routes.PROPERTY_MANAGERS),
              ),
              _row(
                p,
                icon: Icons.emoji_events_outlined,
                title: _t(context, 'Challenges & Rewards', 'Changamoto na Zawadi'),
                subtitle: _t(
                  context,
                  'Monthly challenges and HB Points',
                  'Changamoto za mwezi na HB Points',
                ),
                onTap: () => Get.toNamed(Routes.CHALLENGES_REWARDS),
              ),
              if (!Get.isRegistered<StaffAccessStore>() ||
                  !Get.find<StaffAccessStore>().restricted.value)
                _row(
                  p,
                  icon: controller.isPortfolioManagerSession.value
                      ? Icons.lock_outline
                      : Icons.workspace_premium_outlined,
                  title: _t(
                    context,
                    'Subscription & billing',
                    'Usajili na bili',
                  ),
                  subtitle: controller.isPortfolioManagerSession.value
                      ? _t(
                          context,
                          'Only the host can manage billing plans.',
                          'Mwenyeji pekee anaweza kusimamia mipango ya malipo.',
                        )
                      : _t(
                          context,
                          'View plan, trial, and renewals',
                          'Angalia mpango, majaribio, na upyaaji',
                        ),
                  onTap: controller.openSubscription,
                ),
              _row(
                p,
                icon: Icons.play_circle_outline,
                title: appLocalization.runLeaseReminderNowTitle,
                subtitle: appLocalization.runLeaseReminderNowDescription,
                value: controller.runningLeaseReminderNow.value
                    ? _t(context, 'Running...', 'Inaendeshwa...')
                    : _t(context, 'Tap to run', 'Gusa kuendesha'),
                onTap: controller.runLeaseReminderNow,
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'PROPERTY & DOCUMENTS', 'MALI NA NYARAKA'),
            children: [
              _row(
                p,
                icon: Icons.shield_outlined,
                title: appLocalization.propertyVault,
                subtitle: _t(
                  context,
                  'A secure home for property essentials',
                  'Mahali salama pa muhimu wa mali',
                ),
                onTap: () => Get.toNamed(Routes.PROPERTY_VAULT),
              ),
              _row(
                p,
                icon: Icons.folder_outlined,
                title: appLocalization.legalDocuments,
                subtitle: _t(
                  context,
                  'Your manuals, records and IDs',
                  'Miongozo, kumbukumbu na vitambulisho',
                ),
                onTap: () => Get.toNamed(Routes.DOCUMENTS),
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'HELP & INFORMATION', 'MSAADA NA HABARI'),
            children: [
              _row(
                p,
                icon: Icons.help_outline,
                title: _t(context, 'Help center', 'Kituo cha msaada'),
                subtitle: _t(
                  context,
                  'Guides, feature index, and step-by-step tours',
                  'Miongozo, vipengele, na ziara za hatua kwa hatua',
                ),
                onTap: () => Get.toNamed(Routes.HELP_CENTER),
              ),
              _row(
                p,
                icon: Icons.play_circle_outline,
                title: _t(context, 'Start BnB tour', 'Anza ziara ya BnB'),
                subtitle: _t(
                  context,
                  'Walk through BnB hosting basics',
                  'Pitia misingi ya ukarimu wa BnB',
                ),
                onTap: () => Get.find<GuidedTourService>().startGuideById(
                  'getting_started_bnb',
                ),
              ),
              _row(
                p,
                icon: Icons.play_circle_outline,
                title: _t(context, 'Start Rent tour', 'Anza ziara ya Kodi'),
                subtitle: _t(
                  context,
                  'Walk through rent management basics',
                  'Pitia misingi ya usimamizi wa kodi',
                ),
                onTap: () => Get.find<GuidedTourService>().startGuideById(
                  'getting_started_rent',
                ),
              ),
              _row(
                p,
                icon: Icons.help_outline,
                title: appLocalization.support,
                subtitle: _t(
                  context,
                  'Helpful answers, whenever you need them',
                  'Majibu yanayosaidia, wakati wowote',
                ),
                onTap: () => Get.toNamed(Routes.SUPPORT),
              ),
              _row(
                p,
                icon: Icons.mail_outline,
                title: appLocalization.supportContactHeading,
                subtitle: _t(
                  context,
                  'Talk to the Host Bora team',
                  'Zungumza na timu ya Host Bora',
                ),
                onTap: () => Get.toNamed(Routes.SUPPORT),
              ),
              _row(
                p,
                icon: Icons.feedback_outlined,
                title: appLocalization.sendFeedback,
                subtitle: _t(
                  context,
                  'Your ideas make us better',
                  'Mawazo yako yanatufanya tuwe bora',
                ),
                onTap: () => Get.toNamed(Routes.FEEDBACK),
              ),
              _row(
                p,
                icon: Icons.info_outline,
                title: _t(context, 'About Host Bora', 'Kuhusu Host Bora'),
                subtitle: _t(
                  context,
                  'Thoughtfully built for better hosting',
                  'Imejengwa kwa makini kwa ukarimu bora',
                ),
                onTap: () => Get.toNamed(Routes.ABOUT),
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'PRIVACY & LEGAL', 'FARAGHA NA SHERIA'),
            children: [
              _row(
                p,
                icon: Icons.privacy_tip_outlined,
                title: appLocalization.privacyPolicy,
                subtitle: _t(
                  context,
                  'How your information is handled',
                  'Jinsi taarifa zako zinavyoshughulikiwa',
                ),
                onTap: () => Get.toNamed(Routes.PRIVACY),
              ),
              _row(
                p,
                icon: Icons.description_outlined,
                title: appLocalization.termsOfService,
                subtitle: _t(
                  context,
                  'The details of using Host Bora',
                  'Maelezo ya kutumia Host Bora',
                ),
                onTap: () => Get.toNamed(Routes.TERMS),
              ),
            ],
          ),
          _group(
            p,
            title: _t(context, 'DEVICE & ACCOUNT', 'KIFAA NA AKAUNTI'),
            children: [
              _row(
                p,
                icon: Icons.delete_sweep_outlined,
                title: _t(context, 'Clear offline data', 'Futa data ya ndani'),
                subtitle: _t(
                  context,
                  'Remove device data. Stay signed in.',
                  'Futa data ya kifaa. Baki umeingia.',
                ),
                onTap: controller.promptClearOfflineLocalData,
              ),
              _row(
                p,
                icon: Icons.restart_alt_outlined,
                title: _t(context, 'Reset app', 'Rudisha app kama mpya'),
                subtitle: _t(
                  context,
                  'Start fresh. Your online account stays safe.',
                  'Anza upya. Akaunti yako ya mtandaoni inabaki salama.',
                ),
                danger: true,
                onTap: controller.promptResetApp,
              ),
              _row(
                p,
                icon: Icons.logout,
                title: appLocalization.logout,
                subtitle: _t(context, 'See you again soon', 'Tutaonana tena hivi karibuni'),
                danger: true,
                onTap: () => showSignOutDialog(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 12, color: p.sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _t(
                      context,
                      'Device actions never delete your online account.',
                      'Vitendo vya kifaa havifuti akaunti yako ya mtandaoni.',
                    ),
                    style: TextStyle(fontSize: 11, color: p.sub, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Column(
            children: [
              Text.rich(
                TextSpan(
                  text: 'Host Bora',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    color: p.ink,
                  ),
                  children: [
                    TextSpan(text: '.', style: TextStyle(color: p.teal)),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _t(
                  context,
                  'A little less managing. A lot more living.',
                  'Usimamizi kidogo. Maisha mengi zaidi.',
                ),
                style: TextStyle(fontSize: 12, color: p.sub),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _hostScoreCard(BuildContext context, _P p) {
    final score = controller.hostScore.value;
    if (score == null) {
      if (!controller.hostScoreLoading.value) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LinearProgressIndicator(
          minHeight: 3,
          color: p.teal,
          backgroundColor: p.tint,
        ),
      );
    }
    final progress = score.max == 0 ? 0.0 : score.total / score.max;
    final headline = (score.headline ?? '').trim();
    final hint = (score.hint ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: p.score,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 17, color: p.scoreMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(context, 'YOUR HOST SCORE', 'ALAMA YA MWENYEJI'),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: p.scoreMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.scoreAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      score.level,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline.isNotEmpty
                            ? headline
                            : _t(
                                context,
                                'A little better,\nevery day.',
                                'Bora kidogo,\nkila siku.',
                              ),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _t(
                          context,
                          'Your next milestone is closer than you think.',
                          'Hatua yako ijayo iko karibu kuliko unavyofikiri.',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: p.scoreMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ScoreRing(
                  progress: progress,
                  total: score.total,
                  max: score.max,
                  fill: p.scoreAccent,
                  track: Colors.white.withValues(alpha: 0.13),
                  inner: p.score,
                  muted: p.scoreMuted,
                ),
              ],
            ),
          ),
          if (hint.isNotEmpty || (score.nextLevel ?? '').isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: p.scoreAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint.isNotEmpty
                          ? hint
                          : _t(
                              context,
                              'Keep going to reach ${score.nextLevel}.',
                              'Endelea ili kufikia ${score.nextLevel}.',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: p.scoreMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showHostScoreDetails(context, score),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.north_east,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showHostScoreDetails(BuildContext context, HostScore score) {
    final p = _P.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            score.nextLevel == null || score.nextLevel!.isEmpty
                ? _t(ctx, 'Your host score', 'Alama yako ya mwenyeji')
                : _t(
                    ctx,
                    'Next: ${score.nextLevel}',
                    'Ifuatayo: ${score.nextLevel}',
                  ),
          ),
          content: Text(
            (score.hint ?? '').trim().isNotEmpty
                ? score.hint!
                : _t(
                    ctx,
                    'Keep building consistent hosting habits to make progress.',
                    'Endelea na tabia thabiti za ukarimu ili kuendelea.',
                  ),
            style: TextStyle(fontSize: 14, height: 1.5, color: p.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_t(ctx, 'Got it', 'Sawa')),
            ),
          ],
        );
      },
    );
  }

  Widget _group(
    _P p, {
    required String title,
    required List<Widget> children,
  }) {
    final visible = children.where((child) => child is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 11),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
                color: p.sub,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: p.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.line),
                  visible[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    _P p, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    String? badge,
    Widget? trailing,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final iconColor = danger ? p.danger : p.teal;
    final iconBg = danger ? p.dangerTint : p.tint;
    final titleColor = danger ? p.danger : p.ink;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.tint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: p.teal,
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, height: 1.45, color: p.sub),
                  ),
                ],
              ],
            ),
          ),
          if (value != null && value.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: p.sub),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ] else if (onTap != null)
            Icon(Icons.chevron_right, size: 18, color: p.sub),
        ],
      ),
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: content,
        ),
      ),
    );
  }

  void _showAppLockTimeoutPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _t(context, 'App lock timeout', 'Muda wa kufunga app'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ...SettingsController.appLockTimeoutOptions.map(
                  (seconds) => RadioListTile<int>(
                    value: seconds,
                    groupValue: controller.appLockTimeoutSeconds.value,
                    title: Text(controller.appLockTimeoutLabel(seconds)),
                    onChanged: (value) async {
                      if (value == null) return;
                      await controller.updateAppLockTimeout(value);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showSignOutDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text(appLocalization.cancel),
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget continueButton = TextButton(
      child: Text(appLocalization.yes),
      onPressed: () => controller.logout(),
    );

    AlertDialog alert = AlertDialog(
      title: Text(appLocalization.logout),
      content: Text(appLocalization.logoutConfirm),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({
    required this.on,
    required this.color,
    required this.offColor,
  });

  final bool on;
  final Color color;
  final Color offColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 37,
      height: 23,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? color : offColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 17,
          height: 17,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.progress,
    required this.total,
    required this.max,
    required this.fill,
    required this.track,
    required this.inner,
    required this.muted,
  });

  final double progress;
  final int total;
  final int max;
  final Color fill;
  final Color track;
  final Color inner;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -35 * math.pi / 180,
            child: CustomPaint(
              size: const Size(102, 102),
              painter: _ScoreRingPainter(
                progress: progress,
                fill: fill,
                track: track,
              ),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: inner, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: '$total',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                      color: Colors.white,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: '/$max',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'HOST SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
    required this.progress,
    required this.fill,
    required this.track,
  });

  final double progress;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      true,
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fill != fill ||
        oldDelegate.track != track;
  }
}
