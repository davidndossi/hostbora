import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/db/app_local_database.dart';
import '../../../data/local/draft_listing_store.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/pending_expenses_store.dart';
import '../../../data/local/pending_listings_store.dart';
import '../../../data/local/pending_payments_store.dart';
import '../../../data/local/service/tenant_lease_reminder_service.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/login_response.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../core/widget/base_currency_picker.dart';
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

  final token = ''.obs;
  final account = ''.obs;
  final username = ''.obs;
  final deviceId = ''.obs;
  final userId = ''.obs;
  final isAdmin = false.obs;
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
    Get.toNamed(
      Routes.CHANGE_PIN,
      arguments: {'setup_pin': !hasPin, 'change_pin': hasPin},
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
    final isSw = Get.locale?.languageCode == 'sw';
    Get.dialog(
      AlertDialog(
        title: Text(isSw ? 'Sarafu ya msingi' : 'Base currency'),
        content: SingleChildScrollView(
          child: BaseCurrencyPicker(
            title: isSw
                ? 'Ripoti na chati zitaonyesha kiasi katika sarafu hii'
                : 'Reports and charts will use this currency',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(isSw ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
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

  /// Clears SQLite (all tables) and offline GetStorage queues. Login session is kept.
  Future<void> promptClearOfflineLocalData() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final title = isSw ? 'Futa data ya ndani?' : 'Clear offline data?';
    final body = isSw
        ? 'Hii inafuta mali, mapato, matumizi, wapangaji, foleni za usawazishi, na miruko ya orodha/alipayo iliyohifadhiwa kwenye simu. Huwezi kurudisha.'
        : 'This removes all properties, income, expenses, tenants, sync queues, and offline listing/booking/expense queues stored on this device. This cannot be undone.';
    final confirmLabel = isSw ? 'Futa' : 'Erase';
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
        await AppLocalDatabase.deleteAllRows();
        await PendingBookingsStore().save([]);
        await PendingPaymentsStore().save([]);
        await PendingExpensesStore().save([]);
        await PendingListingsStore().save([]);
        await DraftListingStore().clear();
        showSuccessWithHaptic(
          isSw ? 'Data ya ndani imefutwa.' : 'Offline data cleared.',
        );
      } catch (e) {
        showErrorMessage(e.toString());
      }
    });
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
