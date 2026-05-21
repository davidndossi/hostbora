import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  final BuildContext context;
  Timer? _timer;
  Timer? _expiryCheckTimer;
  bool _lockShownThisResume = false;

  AppLifecycleManager(this.context);

  static const _lockSkipRoutes = <String>{
    Routes.WELCOME_BACK,
    Routes.AUTH,
    Routes.CHANGE_PIN,
    Routes.ONBOARDING,
    Routes.OTP,
    Routes.REGISTRATION,
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockShownThisResume = false;
      _startTimer();
      _expiryCheckTimer?.cancel();
      _expiryCheckTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _cancelTimer();
      _checkTokenAndLogoutIfExpired();
      _startExpiryCheckTimer();
      _maybeShowAppLock();
    }
  }

  void _startExpiryCheckTimer() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkTokenAndLogoutIfExpired();
    });
  }

  Future<void> _checkTokenAndLogoutIfExpired() async {
    try {
      final pref = Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
      final expiryTime = await pref.getString(PreferenceManager.keyExpiryTime, defaultValue: '');
      final token = await pref.getString(PreferenceManager.keyToken, defaultValue: '');
      if (token.isEmpty || expiryTime.isEmpty) return;
      final expiryMs = DateTime.tryParse(expiryTime)?.millisecondsSinceEpoch;
      if (expiryMs == null) return;
      if (DateTime.now().millisecondsSinceEpoch > expiryMs) {
        await pref.clearSession();
        if (Get.currentRoute != Routes.AUTH) {
          Get.offAllNamed(Routes.AUTH);
        }
      }
    } catch (_) {}
  }

  Future<bool> _hasValidSession(PreferenceManager pref) async {
    final token = await pref.getString(PreferenceManager.keyToken, defaultValue: '');
    final expiryTime = await pref.getString(PreferenceManager.keyExpiryTime, defaultValue: '');
    if (token.isEmpty || expiryTime.isEmpty) return false;
    final expiryMs = DateTime.tryParse(expiryTime)?.millisecondsSinceEpoch;
    if (expiryMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch <= expiryMs;
  }

  Future<void> _maybeShowAppLock() async {
    if (_lockShownThisResume) return;

    try {
      final pref = Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
      if (!await _hasValidSession(pref)) return;

      final pinEnabled = await pref.getBool(
        PreferenceManager.keyPinEnabled,
        defaultValue: false,
      );
      final pinCode = await pref.getString(
        PreferenceManager.keyPinCode,
        defaultValue: '',
      );
      if (!pinEnabled || pinCode.length != 4) return;

      final route = Get.currentRoute;
      if (_lockSkipRoutes.contains(route)) return;

      _lockShownThisResume = true;
      if (Get.isRegistered<GetMaterialController>()) {
        await Get.toNamed(Routes.WELCOME_BACK);
      }
    } catch (_) {}
  }

  void startObserving() {
    WidgetsBinding.instance.addObserver(this);
    _checkTokenAndLogoutIfExpired();
    _startExpiryCheckTimer();
  }

  void stopObserving() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _expiryCheckTimer?.cancel();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 15), () {
      debugPrint('App has been in the background for 15 seconds.');
      if (Get.currentRoute == '/receipt') {
        Get.until((route) => route.isFirst);
      }
    });
  }

  void _cancelTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      debugPrint('Timer cancelled because the app is back in the foreground.');
    }
  }
}
