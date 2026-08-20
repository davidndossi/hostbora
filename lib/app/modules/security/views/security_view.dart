import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/security_controller.dart';

class SecurityView extends BaseView<SecurityController> {
  SecurityView({super.key});

  static const _cardBg = Color(0xFFEBEBEB);
  static const _sectionTitle = Color(0xFF8A8A8A);
  static const _bodyText = Color(0xFF333333);
  static const _secondaryText = Color(0xFFA0A0A0);

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.security,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(appLocalization.loginSecurity, [
            _SettingsRow(
              icon: Icons.lock_outline,
              iconColor: AppColors.colorPrimary,
              title: appLocalization.changePassword,
              onTap: controller.changePassword,
            ),
            const Divider(height: 1),
            Obx(
              () => _SettingsRow(
                icon: Icons.grid_view_rounded,
                iconColor: AppColors.colorPrimary,
                title: appLocalization.pinCode,
                trailing: Text(
                  controller.pinEnabled.value
                      ? appLocalization.changeLabel
                      : appLocalization.set,
                  style: TextStyle(
                    fontSize: 15,
                    color: FormSurfaceColors.of(context).isDark ? Colors.white70 : _secondaryText,
                  ),
                ),
                onTap: controller.openPinCode,
              ),
            ),
          ], context),
          const SizedBox(height: 24),
          _buildSection(appLocalization.accessControl, [
            Obx(
              () => _SettingsRow(
                icon: Icons.face_rounded,
                iconColor: AppColors.colorPrimary,
                title: _t(context, en: 'FaceID/TouchID', sw: 'FaceID/TouchID'),
                subtitle: appLocalization.fastLoginVerification,
                trailing: Switch(
                  value: controller.faceIdEnabled.value,
                  onChanged: controller.toggleFaceId,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.colorPrimary,
                ),
                onTap: null,
              ),
            ),
          ], context),
          // const SizedBox(height: 24),
          // _buildSection(appLocalization.additionalProtection, [
          //   _SettingsRow(
          //     icon: Icons.shield_outlined,
          //     iconColor: AppColors.colorPrimary,
          //     title: appLocalization.twoFactorAuth,
          //     trailing: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           appLocalization.notConfigured,
          //           style: TextStyle(
          //             fontSize: 15,
          //             fontWeight: FontWeight.w500,
          //             color: FormSurfaceColors.of(context).isDark ? Colors.white70 : _secondaryText,
          //           ),
          //         ),
          //         const SizedBox(width: 4),
          //         Icon(
          //           Icons.chevron_right,
          //           color: FormSurfaceColors.of(context).isDark ? Colors.white : _bodyText,
          //           size: 22,
          //         ),
          //       ],
          //     ),
          //     onTap: controller.openTwoFactor,
          //   ),
          // ], context),
          const SizedBox(height: 24),
          _buildDeviceSection(context),
          const SizedBox(height: 24),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: FormSurfaceColors.of(context).isDark ? Colors.white70 : _sectionTitle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: FormSurfaceColors.of(context).isDark ? const Color(0xFF1F1F1F) : _cardBg,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDeviceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization.deviceManagement,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: FormSurfaceColors.of(context).isDark ? Colors.white70 : _sectionTitle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: FormSurfaceColors.of(context).isDark ? const Color(0xFF1F1F1F) : _cardBg,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
          ),
          child: Text(
            appLocalization.noRemoteDeviceApi,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: FormSurfaceColors.of(context).isDark ? Colors.white70 : _secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: FormSurfaceColors.of(context).isDark ? Colors.white : _bodyText,
              height: 1.4,
            ),
            children: [
              TextSpan(text: appLocalization.securityPriorityPrefix),
              WidgetSpan(
                child: GestureDetector(
                  onTap: controller.openPrivacyPolicy,
                  child: Text(
                    appLocalization.privacyPolicy,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              TextSpan(text: appLocalization.securityPrioritySuffix),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: c.isDark ? Colors.white70 : _secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...[trailing].whereType<Widget>(),
            if (onTap != null && trailing == null)
              Icon(
                Icons.chevron_right,
                color: c.isDark ? Colors.white : _bodyText,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

const _bodyText = Color(0xFF333333);
const _secondaryText = Color(0xFFA0A0A0);
