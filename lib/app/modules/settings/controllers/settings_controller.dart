import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/login_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

class SettingsController extends BaseController {
  final PreferenceManager _preferenceManager = Get.find(tag: (PreferenceManager)
      .toString());
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final token = ''.obs;
  final account = ''.obs;
  final username = ''.obs;
  final deviceId = ''.obs;
  final userId = ''.obs;
  final isLeader = false.obs;
  final isAdmin = false.obs;
  final deviceName = ''.obs;
  final language = 'en'.obs;
  final isFL = false.obs;
  final roles = <String>[].obs;
  final privacySettings = <String>['PUBLIC', 'PRIVATE', 'COMMUNITY_MEMBERS_ONLY'].obs;

  var darkMode = false.obs;
  var theme = ''.obs;
  var themeDesc = ''.obs;
  var privacy = ''.obs;
  var enableNotifications = false.obs;
  var deathAnnouncements = false.obs;
  var eventReminders = false.obs;
  var receiveCommunityUpdates = false.obs;

  @override
  void onInit() {
    getPrefValues();
    super.onInit();
  }

  @override
  void onClose() {
    savePreference();
    super.onClose();
  }

  void getPrefValues() async {
    token(await _preferenceManager.getString(PreferenceManager.keyToken));
    isFL(await _preferenceManager.getBool(PreferenceManager.keyFirstLogin,
        defaultValue: true));
    String keyUsername = await _preferenceManager.getString(PreferenceManager.keyUsername);
    username(keyUsername);
    deviceName(await _preferenceManager.getString(PreferenceManager.keyFullName));
    deviceId(await _preferenceManager.getString(PreferenceManager.keyDeviceId));
    roles(await _preferenceManager.getStringList(PreferenceManager.keyRoles));
    language(await _preferenceManager.getString(PreferenceManager.keyLang));
    User user = await _preferenceManager.getUser();
    userId(user.id);
    isAdmin(user.isAdmin);
    isLeader(user.isLeader);
    loadSettings();
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
    darkMode.value = !darkMode.value;
    if (darkMode.value) {
      theme('light');
      themeDesc('Light Theme');
    } else {
      theme('dark');
      themeDesc('Dark Theme');
    }
    _preferenceManager.setBool('dark_mode', darkMode.value);
  }

  void toggleEnableNotifications() {
    enableNotifications.value = !enableNotifications.value;
    _preferenceManager.setBool('enable_notifications', enableNotifications.value);
  }

  void toggleDeathAnnouncements() {
    deathAnnouncements.value = !deathAnnouncements.value;
    _preferenceManager.setBool('death_announcements', deathAnnouncements.value);
  }

  void toggleEventReminders() {
    eventReminders.value = !eventReminders.value;
    _preferenceManager.setBool('event_reminders', eventReminders.value);
  }

  void toggleReceiveCommunityUpdates() {
    receiveCommunityUpdates.value = !receiveCommunityUpdates.value;
    _preferenceManager.setBool('receive_community_updates', receiveCommunityUpdates.value);
  }

  void changePrivacySettings(String? value) {
    if (value != null) {
      privacy.value = value;
      _preferenceManager.setString('privacy', privacy.value);
    }
  }

  Future<void> showPrivacyChoices(BuildContext context) async {
    showModalBottomSheet(context: context, builder: (_) => ListView(
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
    ));
  }

  Future<void> loadSettings() async {
    darkMode.value = await _preferenceManager.getBool('dark_mode');
    if (darkMode.value) {
      theme('light');
      themeDesc('Light Theme');
    } else {
      theme('dark');
      themeDesc('Dark Theme');
    }
    enableNotifications.value = await _preferenceManager.getBool('enable_notifications');
    deathAnnouncements.value = await _preferenceManager.getBool('death_announcements');
    eventReminders.value = await _preferenceManager.getBool('event_reminders');
    receiveCommunityUpdates.value = await _preferenceManager.getBool('receive_community_updates');
    privacy.value = await _preferenceManager.getString('privacy');
  }

  void savePreference() {
    Map<String, dynamic> map = {
      'theme': darkMode.value ? 'dark' : 'light',
      'enable_notifications': enableNotifications.value,
      'death_announcements': deathAnnouncements.value,
      'event_reminders': eventReminders.value,
      'receive_community_updates': receiveCommunityUpdates.value,
      'privacy': privacy.value,
      'language': language.value
    };
    callDataServiceSilent(
      _repository.saveUserPreference(userId.value, map),
      onSuccess: (_) => {},
      onError: (_) => {}
    );
  }

  void logout() async {
    await _preferenceManager.clearSession();
    Get.offAllNamed(AppPages.auth);
  }
}
