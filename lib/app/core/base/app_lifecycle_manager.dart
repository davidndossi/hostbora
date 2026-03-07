import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../routes/app_pages.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  final BuildContext context;
  Timer? _timer;
  Timer? _expiryCheckTimer;

  AppLifecycleManager(this.context);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _startTimer();
      _expiryCheckTimer?.cancel();
      _expiryCheckTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _cancelTimer();
      _checkTokenAndLogoutIfExpired();
      _startExpiryCheckTimer();
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
      // When the app comes to the foreground, navigate to the home page
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