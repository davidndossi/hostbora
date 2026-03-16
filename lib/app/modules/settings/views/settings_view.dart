import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:settings_ui/settings_ui.dart';
import '../../../core/values/app_colors.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_view.dart';
import '/app/core/widget/custom_app_bar.dart';
import '/app/modules/settings/controllers/settings_controller.dart';

class SettingsView extends BaseView<SettingsController> {
  SettingsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.settings,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      return SettingsList(
        applicationType: ApplicationType.both,
        platform: DevicePlatform.device,
        lightTheme: const SettingsThemeData(
          dividerColor: Colors.grey,
          settingsListBackground: Colors.white70,
          settingsSectionBackground: Colors.white,
        ),
        darkTheme: const SettingsThemeData(
          dividerColor: Colors.white60,
          settingsListBackground: Colors.black87,
          settingsSectionBackground: Colors.black54,
        ),
        sections: [
          // SettingsSection(
          //   tiles: [
          //     SettingsTile.navigation(
          //       onPressed: (context) {},
          //       title: Obx(() => Text(controller.username.value)),
          //       trailing: const Icon(Icons.chevron_right_outlined),
          //     ),
          //   ],
          // ),
          SettingsSection(
            title: Text(appLocalization.common),
            tiles: [
              SettingsTile(
                onPressed: (context) => controller.setDefaultLocale(),
                leading: const Icon(Icons.language),
                title: Text(appLocalization.language),
                value: Obx(() => Text(controller.language.value == 'en' ? appLocalization.english : appLocalization.swahili)),
              ),
              SettingsTile(
                onPressed: (context) => Get.toNamed(Routes.SEND_SMS),
                leading: const Icon(Icons.sms_outlined),
                title: Text(appLocalization.sendMessage),
                value: Text(appLocalization.sendSmsWhatsapp),
              ),
              SettingsTile(
                onPressed: (context) => controller.toggleTheme(),
                title: Text(appLocalization.theme),
                value: Obx(() => Text(controller.themeDesc.value)),
                leading: const Icon(Icons.brightness_6_outlined),
              ),
            ],
          ),
          SettingsSection(
          title: Text(appLocalization.updates),
          tiles: [
            SettingsTile.switchTile(
              onToggle: (_) => controller.toggleEnableNotifications(),
              initialValue: controller.enableNotifications.value,
              leading: const Icon(Icons.notifications_active),
              title: Text(appLocalization.enableNotifications),
              activeSwitchColor: AppColors.colorPrimary
            ),
            SettingsTile.switchTile(
              onToggle: (_) => controller.toggleEventReminders(),
              leading: const Icon(Icons.event_outlined),
              initialValue: controller.eventReminders.value,
              title: Text(appLocalization.eventReminders),
              activeSwitchColor: AppColors.colorPrimary
            ),
          ]
        ),
        SettingsSection(
          title: Text(appLocalization.security),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.SECURITY),
              leading: const Icon(Icons.security),
              title: Text(appLocalization.security),
              description: Text(appLocalization.securityDescription),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.switchTile(
              onToggle: (_) {
                showToast('Lock app: Development in progress');
              },
              initialValue: true,
              leading: const Icon(Icons.phonelink_lock),
              title: Text(appLocalization.lockApp),
              activeSwitchColor: AppColors.colorPrimary
            ),
            SettingsTile.switchTile(
              onToggle: (_) {
                showToast('Use fingerprint: Development in progress');
              },
              initialValue: true,
              leading: const Icon(Icons.fingerprint),
              title: Text(appLocalization.useFingerprint),
              description: Text(appLocalization.useFingerprintDescription),
              activeSwitchColor: AppColors.colorPrimary
            ),
            // SettingsTile.navigation(
            //   onPressed: (context) => Get.toNamed(Routes.CHANGE_PASSWORD),
            //   leading: const Icon(Icons.lock),
            //   title: Text(appLocalization.changePin)
            // )
          ],
        ),
        SettingsSection(
          title: Text(appLocalization.misc),
          tiles: [
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.PROPERTY_VAULT),
              leading: const Icon(Icons.shield_outlined),
              title: Text(appLocalization.propertyVault),
              description: Text(appLocalization.propertyVaultDescription),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.DOCUMENTS),
              leading: const Icon(Icons.folder_outlined),
              title: Text(appLocalization.legalDocuments),
              description: Text(appLocalization.legalDocumentsDescription),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.ABOUT),
              leading: const Icon(Icons.info_outline),
              title: Text(appLocalization.about),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.SUPPORT),
              leading: const Icon(Icons.help_outline),
              title: Text(appLocalization.support),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.PRIVACY),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(appLocalization.privacyPolicy),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.TERMS),
              leading: const Icon(Icons.description_outlined),
              title: Text(appLocalization.termsOfService),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              title: Text(appLocalization.logout),
              trailing: const Icon(Icons.power_settings_new_outlined),
              onPressed: (context) {
                showSignOutDialog(context);
              },
            ),
          ],
        ),
      ],
    );
    });
  }

  void showSignOutDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text(appLocalization.cancel),
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget continueButton = TextButton(
      child: Text(appLocalization.yes),
      onPressed: () => controller.logout(),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(appLocalization.logout),
      content: Text(appLocalization.logoutConfirm),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

}
