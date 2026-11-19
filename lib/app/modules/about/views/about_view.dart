import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/about_controller.dart';

class AboutView extends BaseView<AboutController> {
  AboutView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  /// Drops a short "Label:" prefix so the card title is not repeated in the body.
  String _withoutLead(String text) {
    final split = text.indexOf(':');
    if (split <= 0 || split > 48) return text;
    return text.substring(split + 1).trim();
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.about,
      isCentered: true,
      backgroundColor: FormSurfaceColors.of(context).scaffold,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final u = FormSurfaceColors.of(context);
    final accent = u.isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.colorPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(context, u, accent),
          const SizedBox(height: 20),
          _sectionLabel(
            context,
            u,
            _t(context, 'WHAT YOU CAN DO', 'UNACHOWEZA KUFANYA'),
          ),
          const SizedBox(height: 10),
          _featureCard(
            context,
            u,
            accent,
            icon: Icons.beach_access_outlined,
            title: _t(context, 'Short stays', 'Makazi ya muda mfupi'),
            body: _withoutLead(appLocalization.aboutBnbFeatures),
          ),
          const SizedBox(height: 12),
          _featureCard(
            context,
            u,
            accent,
            icon: Icons.apartment_outlined,
            title: _t(context, 'Long-term rent', 'Kodi ya muda mrefu'),
            body: _withoutLead(appLocalization.aboutRentFeatures),
          ),
          const SizedBox(height: 12),
          _featureCard(
            context,
            u,
            accent,
            icon: Icons.hub_outlined,
            title: _t(context, 'Both workspaces', 'Sehemu zote mbili'),
            body: _withoutLead(appLocalization.aboutSharedFeatures),
          ),
          const SizedBox(height: 20),
          _versionCard(context, u, accent),
          const SizedBox(height: 16),
          Text(
            'ArtBel Systems · hostbora.co.tz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: u.hint),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, FormSurfaceColors u, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: u.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: u.isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'images/host_bora_logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            appLocalization.paaYangu,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: u.headline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.aboutIntro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: u.secondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, FormSurfaceColors u, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: u.hint,
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    FormSurfaceColors u,
    Color accent, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: u.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: u.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: u.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionCard(BuildContext context, FormSurfaceColors u, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: u.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appLocalization.version,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: u.headline,
              ),
            ),
          ),
          Obx(
            () => Text(
              controller.versionLoading.value ? '…' : controller.versionText.value,
              style: TextStyle(fontSize: 14, color: u.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
