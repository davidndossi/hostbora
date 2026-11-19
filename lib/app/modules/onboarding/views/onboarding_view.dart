import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/base_currency_picker.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends BaseView<OnboardingController> {
  OnboardingView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  /// The themed scaffold, not the old navy splash.
  ///
  /// The welcome screen used to paint itself `#0A1628` with white type and
  /// decorative blobs, then hand the host to a light signup form. That jump
  /// made onboarding look like a different product. It now uses the same
  /// surface as Auth and First Property, so language and currency sit on the
  /// page the rest of the funnel already occupies.
  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final isSw = Get.locale?.languageCode == 'sw';
    final size = MediaQuery.sizeOf(context);
    final c = FormSurfaceColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height < 700 ? 20 : 40),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.tokens.accent.withValues(alpha: 0.10),
                          border: Border.all(
                            color: c.tokens.accent.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'images/host_bora_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.home_work_outlined,
                              size: 48,
                              color: c.tokens.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isSw ? 'Karibu HostBora' : 'Welcome to HostBora',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: c.headline,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSw
                            ? 'Simamia BnB na upangishaji wa muda mrefu kutoka mahali pamoja'
                            : 'Manage BnB stays & long-term rentals\nfrom one powerful app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: c.secondary,
                          height: 1.55,
                        ),
                      ),
                      SizedBox(height: size.height < 700 ? 20 : 32),
                      const _LanguageChoice(),
                      SizedBox(height: size.height < 700 ? 20 : 32),
                      _FeatureRow(
                        icon: Icons.payments_outlined,
                        color: c.tokens.success,
                        title: isSw ? 'Fuatilia Malipo' : 'Track Payments',
                        subtitle: isSw
                            ? 'Malipo ya kodi, bili na michango'
                            : 'Rent, bills & tenant contributions',
                      ),
                      const SizedBox(height: 12),
                      _FeatureRow(
                        icon: Icons.hotel_outlined,
                        color: c.tokens.accent,
                        title: isSw ? 'BnB & Upangishaji' : 'BnB & Rentals',
                        subtitle: isSw
                            ? 'Wageni wa muda mfupi na mpangaji wa muda mrefu'
                            : 'Short-term guests & long-term tenants',
                      ),
                      const SizedBox(height: 12),
                      _FeatureRow(
                        icon: Icons.message_outlined,
                        color: c.tokens.accent,
                        title: isSw ? 'WhatsApp & SMS' : 'WhatsApp & SMS',
                        subtitle: isSw
                            ? 'Tuma ukumbusho wa kodi kiotomatiki'
                            : 'Auto-send rent reminders to tenants',
                      ),
                      const SizedBox(height: 12),
                      _FeatureRow(
                        icon: Icons.cloud_off_outlined,
                        color: c.tokens.warning,
                        title: isSw
                            ? 'Hifadhi Nje ya Mtandao'
                            : 'Offline Storage',
                        subtitle: isSw
                            ? 'Data salama hata bila intaneti'
                            : 'Secure data even without internet',
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BaseCurrencyPicker(
                          title: isSw
                              ? 'Sarafu yako ya msingi'
                              : 'Your base currency',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _BottomCta(isSw: isSw),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Language choice ──────────────────────────────────────────────────────────

/// Picks the app language on the first screen, before anything asks for it.
///
/// Each option is labelled in its own language rather than translated, and the
/// field label carries both, because a picker that names languages in a
/// language the host may not read cannot be used to escape that language.
class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice();

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<AppLocaleController>();
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      final code = locale.code.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LANGUAGE · LUGHA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: c.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LanguageOption(
                  label: 'English',
                  selected: code == 'en',
                  onTap: () => locale.setLanguage('en'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageOption(
                  label: 'Kiswahili',
                  selected: code == 'sw',
                  onTap: () => locale.setLanguage('sw'),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: selected
          ? c.tokens.accent.withValues(alpha: 0.12)
          : c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? c.tokens.accent : c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_outlined,
                  size: 18,
                  color: c.tokens.accent,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.headline : c.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.headline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.secondary,
                    height: 1.4,
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

// ── Bottom CTA panel ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.isSw});

  final bool isSw;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppValues.formButtonHeight + 8,
            child: FilledButton(
              onPressed: () =>
                  Get.find<OnboardingController>().completeOnboarding(),
              style: FilledButton.styleFrom(
                backgroundColor: c.tokens.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_12),
                ),
              ),
              child: Text(
                isSw ? 'Anza Sasa' : 'Get Started',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Get.find<OnboardingController>().goToLogin(),
            child: Text(
              isSw ? 'Nina akaunti tayari' : 'Already have an account?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
