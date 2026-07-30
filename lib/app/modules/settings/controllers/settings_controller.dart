import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';

import '../../../data/local/db/app_local_database.dart';
import '../../all_bookings/controllers/all_bookings_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../financial_overview/controllers/financial_overview_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../listing_details/controllers/listing_details_controller.dart';
import '../../rent/expected_payment_schedule/controllers/rent_expected_payment_schedule_controller.dart';
import '../../rent/tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../../../data/local/service/tenant_lease_reminder_service.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../core/widget/base_currency_dialog.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';
import '/app/core/base/feedback_extensions.dart';

class SettingsController extends BaseController {
  static const tenantReminderTemplateKey = 'tenant_whatsapp_reminder_template';
  static const appLockTimeoutOptions = <int>[15, 30, 60, 300, 900, 1800];

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final token = ''.obs;
  final account = ''.obs;
  final username = ''.obs;
  final deviceId = ''.obs;
  final userId = ''.obs;
  final isAdmin = false.obs;
  final isSalesAgent = false.obs;
  final deviceName = ''.obs;
  final language = 'en'.obs;
  final isFL = false.obs;
  final roles = <String>[].obs;
  final privacySettings = <String>[
    'PUBLIC',
    'PRIVATE',
    'COMMUNITY_MEMBERS_ONLY',
  ].obs;

  var darkMode = false.obs;
  var theme = ''.obs;
  var themeDesc = ''.obs;
  var privacy = ''.obs;
  var enableNotifications = false.obs;
  var deathAnnouncements = false.obs;
  var eventReminders = false.obs;
  var receiveCommunityUpdates = false.obs;
  final tenantReminderTemplate = ''.obs;
  final runningLeaseReminderNow = false.obs;
  final appLockTimeoutSeconds = 15.obs;

  @override
  void onInit() {
    getPrefValues();
    super.onInit();
  }

  @override
  void onClose() {
    // savePreference();
    super.onClose();
  }

  void getPrefValues() async {
    token(await _preferenceManager.getString(PreferenceManager.keyToken));
    isFL(
      await _preferenceManager.getBool(
        PreferenceManager.keyFirstLogin,
        defaultValue: true,
      ),
    );
    String keyUsername = await _preferenceManager.getString(
      PreferenceManager.keyUsername,
    );
    username(keyUsername);
    deviceName(
      await _preferenceManager.getString(PreferenceManager.keyFullName),
    );
    deviceId(await _preferenceManager.getString(PreferenceManager.keyDeviceId));
    roles(await _preferenceManager.getStringList(PreferenceManager.keyRoles));
    language(await _preferenceManager.getString(PreferenceManager.keyLang));
    User user = await _preferenceManager.getUser();
    userId(user.id);
    isAdmin(user.isAdmin);
    isSalesAgent(
      roles.any((r) => r.toLowerCase() == 'sales_agent'),
    );
    loadSettings();
  }

  void openAdminWhatsAppCredentials() {
    if (!isAdmin.value) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Ruhusa ya msimamizi inahitajika'
            : 'Admin access required',
      );
      return;
    }
    Get.toNamed(Routes.ADMIN_WHATSAPP_CREDENTIALS);
  }

  void openAdminSalesAgents() {
    if (!isAdmin.value) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Ruhusa ya msimamizi inahitajika'
            : 'Admin access required',
      );
      return;
    }
    Get.toNamed(Routes.ADMIN_SALES_AGENTS);
  }

  void openSalesAgentDashboard() {
    if (!isSalesAgent.value && !isAdmin.value) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Akaunti ya wakala wa mauzo inahitajika'
            : 'Sales agent account required',
      );
      return;
    }
    Get.toNamed(Routes.SALES_AGENT_DASHBOARD);
  }

  void setDefaultLocale() {
    if (language.value == 'en') {
      language('sw');
    } else {
      language('en');
    }
    String countryCode = language.value == 'sw' ? 'sw_TZ' : 'en_US';
    var locale = Locale(language.value, countryCode);
    Get.updateLocale(locale);
    _preferenceManager.setString(PreferenceManager.keyLang, language.value);
  }

  void toggleTheme() {
    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().toggleTheme();
      _syncThemeLabels(Get.find<ThemeController>().isDarkMode.value);
      return;
    }
    darkMode.value = !darkMode.value;
    _preferenceManager.setBool(kPrefDarkTheme, darkMode.value);
    _syncThemeLabels(darkMode.value);
  }

  void _syncThemeLabels(bool isDark) {
    darkMode.value = isDark;
    if (isDark) {
      theme('dark');
      themeDesc('Dark Theme');
    } else {
      theme('light');
      themeDesc('Light Theme');
    }
  }

  Future<void> openPinSettings() async {
    final pinOn = await _preferenceManager.getBool(
      PreferenceManager.keyPinEnabled,
      defaultValue: false,
    );
    final pinCode = await _preferenceManager.getString(
      PreferenceManager.keyPinCode,
      defaultValue: '',
    );
    final hasPin = pinOn && pinCode.length == 4;
    var confirmRemotePin = false;
    if (!hasPin) {
      try {
        final res = await _repository.getPinStatus();
        confirmRemotePin = res.data is Map && res.data['hasPinSet'] == true;
      } catch (e) {
        logger.w('getPinStatus failed (non-blocking): $e');
      }
    }
    Get.toNamed(
      Routes.CHANGE_PIN,
      arguments: {
        'setup_pin': !hasPin,
        'change_pin': hasPin,
        if (confirmRemotePin) 'confirm_remote_pin': true,
      },
    );
  }

  Future<void> updateAppLockTimeout(int seconds) async {
    if (!appLockTimeoutOptions.contains(seconds)) return;
    appLockTimeoutSeconds.value = seconds;
    await _preferenceManager.setInt(
      PreferenceManager.keyAppLockTimeoutSeconds,
      seconds,
    );
  }

  String appLockTimeoutLabel(int seconds) {
    final isSw = Get.locale?.languageCode == 'sw';
    switch (seconds) {
      case 15:
        return isSw ? 'Sekunde 15' : '15 sec';
      case 30:
        return isSw ? 'Sekunde 30' : '30 sec';
      case 60:
        return isSw ? 'Dakika 1' : '1 min';
      case 300:
        return isSw ? 'Dakika 5' : '5 min';
      case 900:
        return isSw ? 'Dakika 15' : '15 min';
      case 1800:
        return isSw ? 'Dakika 30' : '30 min';
      default:
        return isSw ? 'Sekunde 15' : '15 sec';
    }
  }

  void changePrivacySettings(String? value) {
    if (value != null) {
      privacy.value = value;
      _preferenceManager.setString('privacy', privacy.value);
    }
  }

  Future<void> showPrivacyChoices(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: privacySettings.map((p) {
          return RadioListTile(
            title: Text(p),
            value: p,
            groupValue: privacy.value,
            onChanged: (value) {
              privacy(value);
              changePrivacySettings(value);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> refreshExchangeRates() async {
    final ok = await Get.find<CurrencyService>().refreshRatesFromRemote();
    showSuccessMessage(
      ok ? 'Exchange rates updated' : 'Could not refresh exchange rates',
    );
  }

  void showBaseCurrencyPicker(BuildContext context) {
    showBaseCurrencyDialog(context);
  }

  Future<void> loadSettings() async {
    var isDark = await _preferenceManager.getBool(kPrefDarkTheme);
    final legacyDark = await _preferenceManager.getBool('dark_mode');
    if (legacyDark && !isDark) {
      isDark = true;
      await _preferenceManager.setBool(kPrefDarkTheme, true);
    }
    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().isDarkMode.value = isDark;
    }
    _syncThemeLabels(isDark);
    eventReminders.value = await _preferenceManager.getBool('event_reminders');
    privacy.value = await _preferenceManager.getString('privacy');
    tenantReminderTemplate.value = await _preferenceManager.getString(
      tenantReminderTemplateKey,
      defaultValue: '',
    );
    final savedTimeout = await _preferenceManager.getInt(
      PreferenceManager.keyAppLockTimeoutSeconds,
      defaultValue: 15,
    );
    appLockTimeoutSeconds.value = appLockTimeoutOptions.contains(savedTimeout)
        ? savedTimeout
        : 15;
    if (Get.isRegistered<CurrencyService>()) {
      await Get.find<CurrencyService>().refreshRatesFromRemote();
    }
  }

  Future<void> saveTenantReminderTemplate(String value) async {
    final trimmed = value.trim();
    tenantReminderTemplate.value = trimmed;
    await _preferenceManager.setString(tenantReminderTemplateKey, trimmed);
    showSuccessMessage(
      trimmed.isEmpty
          ? 'Tenant reminder template cleared'
          : 'Tenant reminder template saved',
    );
  }

  String buildTenantReminderTemplatePreview(String template) {
    final trimmed = template.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .replaceAll('{tenantName}', 'Amina Juma')
        .replaceAll('{property}', 'Evergreen Estate Unit 4B')
        .replaceAll('{rentAmount}', '450000')
        .replaceAll('{rentFrequency}', 'Per Month')
        .replaceAll('{leaseEnd}', '2026-04-01')
        .replaceAll('{remainingBalance}', '300000');
  }

  /// Clears all SQLite tables and every GetStorage key on this device.
  /// The login session (token/user) is preserved.
  Future<void> promptClearOfflineLocalData() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final title = isSw ? 'Futa data yote ya ndani?' : 'Clear all offline data?';
    final body = isSw
        ? 'Hii inafuta mali, mapato, matumizi, wapangaji, foleni za usawazishi, hati za vault, historia ya wageni, kumbukumbu za noti, na data yote iliyohifadhiwa kwenye simu. Huwezi kurudisha.'
        : 'This permanently removes all properties, income, expenses, tenants, sync queues, vault documents, guest history, booking overrides, moodboards, entry logs, access codes, and all other offline data stored on this device. This cannot be undone.';
    final confirmLabel = isSw ? 'Futa Yote' : 'Erase All';
    final cancelLabel = isSw ? 'Ghairi' : 'Cancel';

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel, style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok != true) return;

    await runBusy(() async {
      try {
        // 1. Wipe all SQLite tables (properties, income, expenses, tenants,
        //    staff, sync queue, maintenance, loyalty, estimates, exchange rates…).
        await AppLocalDatabase.deleteAllRows();

        // 2. Wipe every GetStorage key (pending queues, vault docs/dirs,
        //    entry logs, booking overrides, moodboards, access codes, ledger
        //    docs, recent access, draft listings, etc.).
        //    Note: login credentials live in FlutterSecureStorage (PreferenceManager)
        //    and are NOT affected by GetStorage().erase().
        await GetStorage().erase();

        // 3. Reload every live controller so their Rx observables reflect
        //    the now-empty database immediately (no stale values on screen).
        await _refreshAllRegisteredControllers();

        showSuccessWithHaptic(
          isSw ? 'Data yote ya ndani imefutwa.' : 'All offline data cleared.',
        );
      } catch (e) {
        showErrorMessage(e.toString());
      }
    });
  }

  /// Calls refreshIfRegistered() on every controller that holds cached data,
  /// so the UI reflects the empty database straight away.
  static Future<void> _refreshAllRegisteredControllers() async {
    await Future.wait([
      HomeController.refreshIfRegistered(),
      DashboardController.refreshIfRegistered(),
      AllBookingsController.refreshIfRegistered(),
      HostCalendarController.refreshIfRegistered(),
      FinancialOverviewController.refreshIfRegistered(),
      ListingDetailsController.refreshIfRegistered(),
      RentTenantLedgerOccupancyController.refreshIfRegistered(),
      RentTenantResidencyPaymentTrackerController.refreshIfRegistered(),
      RentExpectedPaymentScheduleController.refreshIfRegistered(),
    ]);
  }

  Future<void> runLeaseReminderNow() async {
    if (runningLeaseReminderNow.value) return;
    runningLeaseReminderNow.value = true;
    try {
      final service = Get.find<TenantLeaseReminderService>();
      await service.runNow();
      showSuccessMessage('Lease reminder check completed');
    } catch (_) {
      showErrorMessage('Failed to run lease reminder check');
    } finally {
      runningLeaseReminderNow.value = false;
    }
  }

  void logout() async {
    await _preferenceManager.clearSession();
    Get.offAllNamed(AppPages.auth);
  }
}
