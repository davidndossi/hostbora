import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/local/preference/preference_manager.dart';

/// Single source of truth for app language. Keeps [Get.locale], preferences,
/// and [GetMaterialApp] in sync so alert/validation copy follows the UI language.
class AppLocaleController extends GetxController {
  AppLocaleController({PreferenceManager? preferenceManager})
      : _preferenceManager = preferenceManager;

  PreferenceManager? _preferenceManager;

  /// Language code only: `en` or `sw`.
  final code = 'en'.obs;

  Locale get materialLocale =>
      code.value == 'sw' ? const Locale('sw', 'TZ') : const Locale('en', 'US');

  bool get isSw => code.value == 'sw';

  void attachPreferenceManager(PreferenceManager preferenceManager) {
    _preferenceManager = preferenceManager;
  }

  Future<void> loadFromPreferences([PreferenceManager? preferenceManager]) async {
    final pref = preferenceManager ?? _preferenceManager;
    if (pref != null) {
      _preferenceManager = pref;
      final saved = await pref.getString(
        PreferenceManager.keyLang,
        defaultValue: 'en',
      );
      code.value = saved.trim().toLowerCase() == 'sw' ? 'sw' : 'en';
    }
    _apply(code.value, persist: false);
  }

  Future<void> toggle() async {
    await setLanguage(code.value == 'sw' ? 'en' : 'sw');
  }

  Future<void> setLanguage(String languageCode) async {
    final next = languageCode.trim().toLowerCase() == 'sw' ? 'sw' : 'en';
    await _apply(next, persist: true);
  }

  Future<void> _apply(String languageCode, {required bool persist}) async {
    code.value = languageCode;
    final locale = materialLocale;
    Get.locale = locale;
    Get.updateLocale(locale);
    Intl.defaultLocale = languageCode == 'sw' ? 'sw_TZ' : 'en_US';
    if (persist) {
      final pref = _preferenceManager;
      if (pref != null) {
        await pref.setString(PreferenceManager.keyLang, languageCode);
      }
    }
  }
}
