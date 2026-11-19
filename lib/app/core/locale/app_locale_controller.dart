import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../data/model/update_preference_request.dart';
import '../../data/repository/app_repository.dart';

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
    unawaited(_pushRemote(next));
  }

  /// After sign-in: use the account language on a new device, or upload the
  /// language chosen during onboarding when the account has none yet.
  Future<void> syncWithAccount() async {
    try {
      final preferLocal = await _preferenceManager?.getBool(
            PreferenceManager.keyPendingFirstProperty,
            defaultValue: false,
          ) ??
          false;
      if (preferLocal) {
        await _pushRemote(code.value);
        return;
      }
      final remote = await _fetchRemoteLanguage();
      if (remote != null) {
        if (remote != code.value) {
          await _apply(remote, persist: true);
        }
        return;
      }
      await _pushRemote(code.value);
    } catch (_) {
      // Local language stays; sync is best-effort.
    }
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

  Future<String?> _fetchRemoteLanguage() async {
    if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
      return null;
    }
    final response = await Get.find<AppRepository>(
      tag: (AppRepository).toString(),
    ).getSettingsPreferences();
    return UpdatePreferenceRequest.parseLanguage(response.data) ??
        UpdatePreferenceRequest.parseLanguage(response.toJson());
  }

  Future<void> _pushRemote(String languageCode) async {
    if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
      return;
    }
    try {
      await Get.find<AppRepository>(tag: (AppRepository).toString())
          .updateSettingsPreferences(
        UpdatePreferenceRequest(language: languageCode),
      );
    } catch (_) {
      // Local preference is source of truth offline; sync is best-effort.
    }
  }
}
