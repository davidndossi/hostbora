import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../all_bookings/controllers/all_bookings_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../financial_overview/controllers/financial_overview_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';
import '../../listing_details/controllers/listing_details_controller.dart';
import '../../main/controllers/bottom_nav_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '../../rent/expected_payment_schedule/controllers/rent_expected_payment_schedule_controller.dart';
import '../../rent/tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../../../data/local/service/local_account_data_reset.dart';
import '../../../data/local/service/session_service.dart';
import '../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../data/local/service/tenant_lease_reminder_service.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/host_score.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/widget/base_currency_dialog.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/access/staff_access.dart';
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
  final accountName = ''.obs;
  final accountEmail = ''.obs;
  final accountPhone = ''.obs;
  final deviceId = ''.obs;
  final userId = ''.obs;
  final isAdmin = false.obs;
  final isSalesAgent = false.obs;
  /// True when this session is managing another host's portfolio (no billing).
  final isPortfolioManagerSession = false.obs;
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
  final appLockTimeoutSeconds = PreferenceManager.defaultAppLockTimeoutSeconds.obs;
  final hostScore = Rxn<HostScore>();
  final hostScoreLoading = false.obs;

  @override
  void onInit() {
    getPrefValues();
    if (Get.isRegistered<AppLocaleController>()) {
      final localeCtrl = Get.find<AppLocaleController>();
      language(localeCtrl.code.value);
      ever<String>(localeCtrl.code, (c) => language(c));
    }
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
    User? user;
    try {
      user = await _preferenceManager.getUser();
    } catch (_) {
      user = null;
    }
    _applyAccountProfile(user);
    userId(user?.id);
    final userRoles = user?.roles ?? const <String>[];
    final mergedRoles = userRoles.isNotEmpty ? userRoles : roles.toList();
    if (userRoles.isNotEmpty) roles(mergedRoles);
    isAdmin(
      (user?.isAdmin ?? false) ||
          mergedRoles.any((r) => r.toLowerCase() == 'admin'),
    );
    isSalesAgent(
      mergedRoles.any((r) => r.toLowerCase() == 'sales_agent'),
    );
    isPortfolioManagerSession(
      await _preferenceManager.getBool(
        PreferenceManager.keyIsPortfolioManager,
        defaultValue: false,
      ),
    );
    loadSettings();
    loadHostScore();
  }

  void _applyAccountProfile(User? user) {
    final name = (user?.fullName ?? '').trim();
    final storedName = deviceName.value.trim();
    accountName(name.isNotEmpty ? name : storedName);

    accountEmail((user?.email ?? '').trim());

    final phone = (user?.msisdn ?? '').trim();
    final storedPhone = username.value.trim();
    accountPhone(phone.isNotEmpty ? phone : storedPhone);
  }

  Future<void> loadHostScore() async {
    hostScoreLoading(true);
    try {
      final response = await _repository.getHostScore();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        hostScore(HostScore.fromJson(Map<String, dynamic>.from(data)));
      }
    } catch (_) {
      // Keep the settings screen usable if score is unavailable.
    } finally {
      hostScoreLoading(false);
    }
  }

  void openSubscription() {
    if (Get.isRegistered<StaffAccessStore>() &&
        Get.find<StaffAccessStore>().restricted.value) {
      Get.find<StaffAccessStore>().showDenied();
      return;
    }
    if (isPortfolioManagerSession.value) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Wasimamizi hawawezi kufikia bili au mipango.'
            : 'Managers cannot access billing or plans.',
      );
      return;
    }
    Get.toNamed(Routes.SUBSCRIPTION);
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

  void openAdminGrowthMetrics() {
    if (!isAdmin.value) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Ruhusa ya msimamizi inahitajika'
            : 'Admin access required',
      );
      return;
    }
    Get.toNamed(Routes.ADMIN_GROWTH_METRICS);
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
    final next = language.value == 'en' ? 'sw' : 'en';
    language(next);
    if (Get.isRegistered<AppLocaleController>()) {
      unawaited(Get.find<AppLocaleController>().setLanguage(next));
    } else {
      final locale =
          next == 'sw' ? const Locale('sw', 'TZ') : const Locale('en', 'US');
      Get.updateLocale(locale);
      unawaited(
        _preferenceManager.setString(PreferenceManager.keyLang, next),
      );
    }
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
      defaultValue: PreferenceManager.defaultAppLockTimeoutSeconds,
    );
    appLockTimeoutSeconds.value = appLockTimeoutOptions.contains(savedTimeout)
        ? savedTimeout
        : PreferenceManager.defaultAppLockTimeoutSeconds;
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
    // Says what survives as well as what goes. Without the second paragraph
    // "all other offline data… cannot be undone" reads as a factory reset,
    // and hosts expect to land back on onboarding. Use Reset app for that.
    final body = isSw
        ? 'Hii inafuta rekodi zilizohifadhiwa kwenye simu hii: mali, mapato, matumizi, wapangaji, foleni za usawazishi, hati za vault, historia ya wageni, kumbukumbu za noti, na misimbo ya kuingia. Huwezi kurudisha.\n\nHaifuti: utaendelea kuwa umeingia, na PIN, lugha na mapendeleo yako yatabaki. Kwa kuanza upya kabisa, tumia Rudisha app kama mpya.'
        : 'This permanently removes the records stored on this device: properties, income, expenses, tenants, sync queues, vault documents, guest history, booking overrides, moodboards, entry logs and access codes. This cannot be undone.\n\nIt does not sign you out, and your PIN, language and other preferences stay as they are. To start over completely, use Reset app instead.';
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
        // Same path as Reset app: drop the DB file, not just its rows.
        // DELETE FROM left the open handle (and the leftover
        // host_bora_local.db) looking like the wipe had done nothing.
        await LocalAccountDataReset.wipe();

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

  /// Returns the device to a just-installed state and relaunches at onboarding.
  ///
  /// Distinct from [promptClearOfflineLocalData], which deliberately keeps the
  /// sign-in session and every app preference. That is why clearing offline
  /// data never brought onboarding back: the gate is `seen_onboarding`, which
  /// lives in secure storage alongside the auth token and is untouched by a
  /// records-only wipe.
  ///
  /// Signs the account out of this device as a consequence, not a side effect
  /// — a reset that left a live token would not be a fresh install.
  Future<void> promptResetApp() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isSw ? 'Rudisha app kama mpya?' : 'Reset app?'),
        content: Text(
          isSw
              ? 'Hii inafuta kila kitu kwenye simu hii: mali, mapato, matumizi, wapangaji, hati, PIN yako, mapendeleo yako, na utakutolewa kwenye akaunti. App itaanza upya kama mpya.\n\nAkaunti yako ya mtandaoni haiguswi — unaweza kuingia tena na data yako ya seva itapakiwa.'
              : 'This erases everything on this device: properties, income, expenses, tenants, documents, your PIN, your preferences, and it signs you out. The app restarts as if freshly installed.\n\nYour online account is not deleted — you can sign back in and your server data will sync down again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              isSw ? 'Ghairi' : 'Cancel',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              isSw ? 'Rudisha Upya' : 'Reset App',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok != true) return;

    // Only the wipe runs inside runBusy. Navigating away from Settings
    // disposes this controller (it is a fenix lazyPut on the Settings route),
    // and runBusy's `finally` writes to `isBusy` — on a disposed Rx that
    // throws. So the data work finishes first, then the app moves.
    final wiped = await runBusy<bool>(() async {
      try {
        // Reminders are queued with the OS, not in our tables, so they have
        // to be dropped explicitly or they fire for deleted records.
        if (Get.isRegistered<LocalNotificationSchedulerService>()) {
          await Get.find<LocalNotificationSchedulerService>().cancelAll();
        }

        // SQLite rows + every GetStorage key.
        await LocalAccountDataReset.wipe();

        // Before touching storage, so the in-memory copies go too. Permanent
        // services survive Get.offAllNamed, and one still holding a cached
        // user would have the app half signed-in until the next cold start.
        if (Get.isRegistered<SessionService>()) {
          await Get.find<SessionService>().clearFullSession();
        }

        // The part a records-only wipe skips: secure storage, which holds the
        // token, the user object, the PIN and `seen_onboarding`. Clearing it
        // is what actually makes the next launch look like a first launch.
        await _preferenceManager.clear();
        return true;
      } catch (e) {
        showErrorMessage(e.toString());
        return false;
      }
    });
    if (wiped != true) return;

    await Get.offAllNamed(Routes.ONBOARDING);
    _disposeAccountScopedControllers();
  }

  /// Drops the controllers that outlive a route so a reset cannot leave the
  /// previous account's data on screen.
  ///
  /// These three are registered `permanent: true` in [MainBinding], which
  /// means `Get.offAllNamed` does not dispose them — and because the binding
  /// guards two of them with `isRegistered`, signing in again reuses the same
  /// instances and never reloads. The host sees their old properties against
  /// an empty database, which reads as the reset having done nothing.
  ///
  /// Deleted rather than refreshed: the app is on its way back to onboarding,
  /// so the right state is no state. The next sign-in runs the binding again
  /// and builds them from whatever the database holds then. `force` is
  /// required because GetX will not delete a permanent instance otherwise.
  ///
  /// Called after navigating away, so nothing is still subscribed to them.
  /// The fenix controllers are left alone: they are tied to routes the
  /// navigation above has already torn down.
  void _disposeAccountScopedControllers() {
    Get.delete<MyPropertiesController>(force: true);
    Get.delete<MainController>(force: true);
    Get.delete<BottomNavController>(force: true);
  }

  /// Calls refreshIfRegistered() on every controller that holds cached data,
  /// so the UI reflects the empty database straight away.
  ///
  /// Missing one of these does not look like a stale cache to the host; it
  /// looks like the wipe silently failed, because the screen still lists the
  /// rows that are no longer in the database.
  static Future<void> _refreshAllRegisteredControllers() async {
    await Future.wait([
      // Registered `permanent: true`, so unlike the fenix controllers below it
      // is never disposed with its route and will hold a deleted property
      // list indefinitely.
      MyPropertiesController.refreshIfRegistered(),
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
