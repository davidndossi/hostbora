import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
                    color: _isDark(context) ? Colors.white70 : _secondaryText,
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
                  onChanged: (_) => controller.faceIdEnabled.value =
                      !controller.faceIdEnabled.value,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.colorPrimary,
                ),
                onTap: null,
              ),
            ),
          ], context),
          const SizedBox(height: 24),
          _buildSection(appLocalization.additionalProtection, [
            _SettingsRow(
              icon: Icons.shield_outlined,
              iconColor: AppColors.colorPrimary,
              title: appLocalization.twoFactorAuth,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appLocalization.enabled,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: _isDark(context) ? Colors.white : _bodyText,
                    size: 22,
                  ),
                ],
              ),
              onTap: controller.openTwoFactor,
            ),
          ], context),
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
            color: _isDark(context) ? Colors.white70 : _sectionTitle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isDark(context) ? const Color(0xFF1F1F1F) : _cardBg,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appLocalization.deviceManagement,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: _isDark(context) ? Colors.white70 : _sectionTitle,
              ),
            ),
            GestureDetector(
              onTap: controller.logoutAllDevices,
              child: Text(
                appLocalization.logOutAll,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.paaYanguAlert,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isDark(context) ? const Color(0xFF1F1F1F) : _cardBg,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
          ),
          child: Column(
            children: [
              ...controller.devices.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final isLast = i == controller.devices.length - 1;
                return Column(
                  children: [
                    _DeviceRow(
                      device: d,
                      isDark: _isDark(context),
                      onLogout: () => controller.logoutDevice(d),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }),
            ],
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
              color: _isDark(context) ? Colors.white : _bodyText,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      color: isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : _secondaryText,
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
                color: isDark ? Colors.white : _bodyText,
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

class _DeviceRow extends StatelessWidget {
  final DeviceSession device;
  final bool isDark;
  final VoidCallback onLogout;

  const _DeviceRow({
    required this.device,
    required this.isDark,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            device.name.contains('Mac') ? Icons.laptop_mac : Icons.phone_iphone,
            size: 22,
            color: isDark ? Colors.white : _bodyText,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.colorPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.current,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.location} • ${device.lastActive}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : _secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (!device.isCurrent)
            IconButton(
              onPressed: onLogout,
              icon: Icon(
                Icons.logout,
                size: 20,
                color: isDark ? Colors.white : _bodyText,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }
}
