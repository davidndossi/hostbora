import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:settings_ui/settings_ui.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/help/guided_tour_service.dart';
import '../../../core/access/staff_access.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_view.dart';
import '/app/core/widget/custom_app_bar.dart';
import '/app/modules/settings/controllers/settings_controller.dart';

class SettingsView extends BaseView<SettingsController> {
  SettingsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  Text _tileTitle(BuildContext context, String value) {
    final theme = Theme.of(context);
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Text _tileValue(BuildContext context, String value) {
    final theme = Theme.of(context);
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Text _tileDescription(BuildContext context, String value) {
    final theme = Theme.of(context);
    return Text(
      value,
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.settings,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SettingsList(
      applicationType: ApplicationType.both,
      platform: DevicePlatform.device,
      lightTheme: SettingsThemeData(
        dividerColor: Theme.of(context).dividerColor,
        settingsListBackground: Theme.of(context).colorScheme.surface,
        settingsSectionBackground: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow,
      ),
      darkTheme: SettingsThemeData(
        dividerColor: Theme.of(context).dividerColor,
        settingsListBackground: Theme.of(context).colorScheme.surface,
        settingsSectionBackground: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow,
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
          title: _tileTitle(context, appLocalization.common),
          tiles: [
            if (!Get.isRegistered<StaffAccessStore>() ||
                !Get.find<StaffAccessStore>().restricted.value)
              SettingsTile.navigation(
              onPressed: (_) => controller.openSubscription(),
              leading: const Icon(Icons.workspace_premium_outlined),
              title: _tileTitle(
                context,
                _t(context, 'Subscription & billing', 'Usajili na bili'),
              ),
              description: Obx(
                () => _tileDescription(
                  context,
                  controller.isPortfolioManagerSession.value
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
                ),
              ),
              trailing: Obx(
                () => Icon(
                  controller.isPortfolioManagerSession.value
                      ? Icons.lock_outline
                      : Icons.chevron_right_outlined,
                ),
              ),
            ),
            SettingsTile(
              onPressed: (context) =>
                  controller.showBaseCurrencyPicker(context),
              leading: const Icon(Icons.payments_outlined),
              title: _tileTitle(
                context,
                _t(context, 'Base currency', 'Sarafu ya msingi'),
              ),
              value: Obx(
                () => _tileValue(
                  context,
                  Get.find<CurrencyService>().baseCurrency.value,
                ),
              ),
            ),
            SettingsTile(
              onPressed: (context) => controller.refreshExchangeRates(),
              leading: const Icon(Icons.currency_exchange),
              title: _tileTitle(
                context,
                _t(
                  context,
                  'Refresh exchange rates',
                  'Sasisha viwango vya ubadilishaji',
                ),
              ),
            ),
            SettingsTile(
              onPressed: (context) => controller.setDefaultLocale(),
              leading: const Icon(Icons.language),
              title: _tileTitle(context, appLocalization.language),
              value: Obx(
                () => _tileValue(
                  context,
                  controller.language.value == 'en'
                      ? appLocalization.english
                      : appLocalization.swahili,
                ),
              ),
            ),
            // SettingsTile(
            //   onPressed: (context) => Get.toNamed(Routes.SEND_SMS),
            //   leading: const Icon(Icons.sms_outlined),
            //   title: _tileTitle(context, appLocalization.sendMessage),
            //   value: _tileValue(context, appLocalization.sendSmsWhatsapp),
            // ),
            // SettingsTile.navigation(
            //   onPressed: (context) =>
            //       _showTenantReminderTemplateDialog(context),
            //   leading: const Icon(Icons.chat_outlined),
            //   title: _tileTitle(
            //     context,
            //     appLocalization.tenantReminderTemplateTitle,
            //   ),
            //   description: _tileDescription(
            //     context,
            //     appLocalization.tenantReminderTemplateDescription,
            //   ),
            //   value: Obx(
            //     () => _tileValue(
            //       context,
            //       controller.tenantReminderTemplate.value.trim().isEmpty
            //           ? _t(context, 'Not set', 'Haijawekwa')
            //           : _t(context, 'Configured', 'Imewekwa'),
            //     ),
            //   ),
            //   trailing: const Icon(Icons.chevron_right_outlined),
            // ),
            SettingsTile(
              onPressed: (context) => controller.runLeaseReminderNow(),
              leading: const Icon(Icons.play_circle_outline),
              title: _tileTitle(
                context,
                appLocalization.runLeaseReminderNowTitle,
              ),
              description: _tileDescription(
                context,
                appLocalization.runLeaseReminderNowDescription,
              ),
              value: Obx(
                () => _tileValue(
                  context,
                  controller.runningLeaseReminderNow.value
                      ? _t(context, 'Running...', 'Inaendeshwa...')
                      : _t(context, 'Tap to run', 'Gusa kuendesha'),
                ),
              ),
            ),
            SettingsTile(
              onPressed: (context) => controller.toggleTheme(),
              title: _tileTitle(context, appLocalization.theme),
              value: Obx(() => _tileValue(context, controller.themeDesc.value)),
              leading: const Icon(Icons.brightness_6_outlined),
            ),
          ],
        ),
        // SettingsSection(
        //   title: _tileTitle(context, appLocalization.updates),
        //   tiles: [
        //     SettingsTile.switchTile(
        //       onToggle: (_) => controller.toggleEnableNotifications(),
        //       initialValue: controller.enableNotifications.value,
        //       leading: const Icon(Icons.notifications_active),
        //       title: _tileTitle(context, appLocalization.enableNotifications),
        //       activeSwitchColor: AppColors.colorPrimary,
        //     ),
        //     SettingsTile.switchTile(
        //       onToggle: (_) => controller.toggleEventReminders(),
        //       leading: const Icon(Icons.event_outlined),
        //       initialValue: controller.eventReminders.value,
        //       title: _tileTitle(context, appLocalization.eventReminders),
        //       activeSwitchColor: AppColors.colorPrimary,
        //     ),
        //   ],
        // ),
        SettingsSection(
          title: _tileTitle(context, _t(context, 'Help', 'Msaada')),
          tiles: [
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.HELP_CENTER),
              leading: const Icon(Icons.help_outline_rounded),
              title: _tileTitle(
                context,
                _t(context, 'Help center', 'Kituo cha msaada'),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Guides, feature index, and step-by-step tours',
                  'Miongozo, vipengele, na ziara za hatua kwa hatua',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) async {
                await Get.find<GuidedTourService>().startGuideById(
                  'getting_started_bnb',
                );
              },
              leading: const Icon(Icons.play_circle_outline),
              title: _tileTitle(
                context,
                _t(context, 'Start BnB tour', 'Anza ziara ya BnB'),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) async {
                await Get.find<GuidedTourService>().startGuideById(
                  'getting_started_rent',
                );
              },
              leading: const Icon(Icons.play_circle_outline),
              title: _tileTitle(
                context,
                _t(context, 'Start Rent tour', 'Anza ziara ya Kodi'),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
          ],
        ),
        SettingsSection(
          title: _tileTitle(context, appLocalization.security),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.SECURITY),
              leading: const Icon(Icons.security),
              title: _tileTitle(context, appLocalization.security),
              description: _tileDescription(
                context,
                appLocalization.securityDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => _showAppLockTimeoutPicker(context),
              leading: const Icon(Icons.timer_outlined),
              title: _tileTitle(
                context,
                _t(context, 'App lock timeout', 'Muda wa kufunga app'),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Show welcome screen after the app stays in the background',
                  'Onyesha skrini ya karibu baada ya app kukaa nyuma',
                ),
              ),
              value: Obx(
                () => _tileValue(
                  context,
                  controller.appLockTimeoutLabel(
                    controller.appLockTimeoutSeconds.value,
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => controller.openAdminWhatsAppCredentials(),
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: _tileTitle(
                context,
                _t(
                  context,
                  'WhatsApp credentials (admin)',
                  'WhatsApp (msimamizi)',
                ),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Per-host Business API status (admins only)',
                  'Hali ya API kwa kila mwenye nyumba (wasimamizi tu)',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => controller.openAdminSalesAgents(),
              leading: const Icon(Icons.groups_outlined),
              title: _tileTitle(
                context,
                _t(context, 'Sales agents (admin)', 'Wakala wa mauzo (msimamizi)'),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Create agents, track recruits and commissions',
                  'Unda wakala, fuatilia wateja na kamisheni',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => controller.openSalesAgentDashboard(),
              leading: const Icon(Icons.insights_outlined),
              title: _tileTitle(
                context,
                _t(context, 'My sales dashboard', 'Dashibodi yangu ya mauzo'),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Recruits, active subscribers and commission',
                  'Waliowajiliwa, wanaofanya kazi na kamisheni',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => controller.openPinSettings(),
              leading: const Icon(Icons.pin_outlined),
              title: _tileTitle(context, appLocalization.changePinTitle),
              description: _tileDescription(
                context,
                appLocalization.changePinDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            // SettingsTile.navigation(
            //   onPressed: (context) => showToast(
            //     _t(
            //       context,
            //       'This feature is coming soon',
            //       'Huduma hii inakuja hivi karibuni',
            //     ),
            //   ),
            //   leading: const Icon(Icons.phonelink_lock),
            //   title: _tileTitle(context, appLocalization.lockApp),
            //   value: _tileValue(
            //     context,
            //     _t(context, 'Coming soon', 'Inakuja'),
            //   ),
            //   trailing: const Icon(Icons.chevron_right_outlined),
            // ),
            // SettingsTile.navigation(
            //   onPressed: (context) => showToast(
            //     _t(
            //       context,
            //       'This feature is coming soon',
            //       'Huduma hii inakuja hivi karibuni',
            //     ),
            //   ),
            //   leading: const Icon(Icons.fingerprint),
            //   title: _tileTitle(context, appLocalization.useFingerprint),
            //   description: _tileDescription(
            //     context,
            //     appLocalization.useFingerprintDescription,
            //   ),
            //   value: _tileValue(
            //     context,
            //     _t(context, 'Coming soon', 'Inakuja'),
            //   ),
            //   trailing: const Icon(Icons.chevron_right_outlined),
            // ),
            // SettingsTile.navigation(
            //   onPressed: (context) => Get.toNamed(Routes.CHANGE_PASSWORD),
            //   leading: const Icon(Icons.lock),
            //   title: Text(appLocalization.changePin)
            // )
          ],
        ),
        SettingsSection(
          title: _tileTitle(context, appLocalization.misc),
          tiles: [
            SettingsTile.navigation(
              onPressed: (context) => controller.promptClearOfflineLocalData(),
              leading: const Icon(Icons.delete_sweep_outlined),
              title: _tileTitle(
                context,
                _t(context, 'Clear offline data', 'Futa data ya ndani'),
              ),
              description: _tileDescription(
                context,
                _t(
                  context,
                  'Erase all local database rows and offline queues on this device. Your sign-in session stays active.',
                  'Futa rekodi zote za hifadhidata na foleni za ndani kwenye simu. Kipindi chako cha kuingia kitaendelea.',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.PROPERTY_VAULT),
              leading: const Icon(Icons.shield_outlined),
              title: _tileTitle(context, appLocalization.propertyVault),
              description: _tileDescription(
                context,
                appLocalization.propertyVaultDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.DOCUMENTS),
              leading: const Icon(Icons.folder_outlined),
              title: _tileTitle(context, appLocalization.legalDocuments),
              description: _tileDescription(
                context,
                appLocalization.legalDocumentsDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.ABOUT),
              leading: const Icon(Icons.info_outline),
              title: _tileTitle(context, appLocalization.about),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.SUPPORT),
              leading: const Icon(Icons.contact_mail_outlined),
              title: _tileTitle(context, appLocalization.supportContactHeading),
              description: _tileDescription(
                context,
                appLocalization.settingsContactUsDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.FEEDBACK),
              leading: const Icon(Icons.feedback_outlined),
              title: _tileTitle(context, appLocalization.sendFeedback),
              description: _tileDescription(
                context,
                appLocalization.settingsSendFeedbackDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.SUPPORT),
              leading: const Icon(Icons.help_outline),
              title: _tileTitle(context, appLocalization.support),
              description: _tileDescription(
                context,
                appLocalization.settingsSupportDescription,
              ),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.PRIVACY),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: _tileTitle(context, appLocalization.privacyPolicy),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              onPressed: (context) => Get.toNamed(Routes.TERMS),
              leading: const Icon(Icons.description_outlined),
              title: _tileTitle(context, appLocalization.termsOfService),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            SettingsTile.navigation(
              title: _tileTitle(context, appLocalization.logout),
              trailing: const Icon(Icons.power_settings_new_outlined),
              onPressed: (context) {
                showSignOutDialog(context);
              },
            ),
          ],
        ),
      ],
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
      actions: [cancelButton, continueButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _showTenantReminderTemplateDialog(BuildContext context) {
    const placeholders = <String>[
      '{tenantName}',
      '{property}',
      '{rentAmount}',
      '{rentFrequency}',
      '{leaseEnd}',
      '{remainingBalance}',
    ];
    final textController = TextEditingController(
      text: controller.tenantReminderTemplate.value,
    );
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(appLocalization.tenantReminderTemplateTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t(
                      context,
                      'You can use these placeholders in your message:',
                      'Unaweza kutumia nafasi hizi katika ujumbe wako:',
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  ...placeholders.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SelectableText(
                        p,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _t(
                        context,
                        'Example: Hello {tenantName}, your tenancy has ended. Please renew and pay your outstanding balance.',
                        'Mfano: Hujambo {tenantName}, muda wa upangaji umeisha. Tafadhali huisha mkataba na ulipie deni lililosalia.',
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                appLocalization.cancel,
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                await controller.saveTenantReminderTemplate('');
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                appLocalization.clear,
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                final preview = controller.buildTenantReminderTemplatePreview(
                  textController.text,
                );
                if (preview.trim().isEmpty) {
                  controller.showErrorMessage(
                    _t(
                      context,
                      'Enter a template first to preview',
                      'Weka kwanza kiolezo ili kuona hakikisho',
                    ),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text(appLocalization.templatePreviewTitle),
                      content: Text(preview),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            appLocalization.closeLabel,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                appLocalization.previewLabel,
                style: TextStyle(fontSize: 16),
              ),
            ),
            FilledButton(
              onPressed: () async {
                await controller.saveTenantReminderTemplate(
                  textController.text,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(appLocalization.save, style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}
