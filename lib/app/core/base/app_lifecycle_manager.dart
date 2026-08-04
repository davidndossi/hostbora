import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../data/local/service/session_service.dart';
import '../../routes/app_pages.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  final BuildContext context;
  Timer? _timer;
  Timer? _expiryCheckTimer;
  bool _lockShownThisResume = false;
  bool _isPaused = false;
  DateTime? _pausedAt;

  AppLifecycleManager(this.context);

  static const _lockSkipRoutes = AppPages.publicAuthRoutes;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isPaused = true;
      final pausedAt = DateTime.now();
      _pausedAt = pausedAt;
      _saveBackgroundedAt(pausedAt);
      _lockShownThisResume = false;
      _startTimer();
      _expiryCheckTimer?.cancel();
      _expiryCheckTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      _cancelTimer();
      _checkTokenAndRefreshIfNeeded();
      _startExpiryCheckTimer();
      _maybeShowAppLock();
    }
  }

  void _startExpiryCheckTimer() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkTokenAndRefreshIfNeeded();
    });
  }

  Future<void> _checkTokenAndRefreshIfNeeded() async {
    try {
      // Registration / OTP / onboarding have no session — never kick to Login.
      if (AppPages.isPublicAuthRoute()) return;

      final pref = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      if (!await SessionService.hasLocalSession(pref)) {
        await _clearAndGoToAuth(pref);
        return;
      }
      if (!Get.isRegistered<SessionService>()) return;
      final session = Get.find<SessionService>();
      if (await session.isAccessTokenValid()) return;
      final refreshed = await session.ensureValidSession();
      if (!refreshed && !AppPages.isPublicAuthRoute()) {
        await session.clearFullSession();
        Get.offAllNamed(Routes.AUTH);
      }
    } catch (_) {}
  }

  Future<void> _clearAndGoToAuth(PreferenceManager pref) async {
    await pref.clearSession();
    Get.offAllNamed(Routes.AUTH);
  }

  Future<bool> _hasValidSession(PreferenceManager pref) async {
    return SessionService.hasLocalSession(pref);
  }

  Future<void> _maybeShowAppLock() async {
    if (_lockShownThisResume) return;

    try {
      final pref = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      if (!await _hasValidSession(pref)) return;
      if (!await _hasAppLockTimeoutElapsed(pref)) return;

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

  Future<bool> _hasAppLockTimeoutElapsed(PreferenceManager pref) async {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return false;

    final timeoutSeconds = await _appLockTimeoutSeconds(pref);
    return DateTime.now().difference(pausedAt) >=
        Duration(seconds: timeoutSeconds);
  }

  void startObserving() {
    WidgetsBinding.instance.addObserver(this);
    _checkTokenAndRefreshIfNeeded();
    _startExpiryCheckTimer();
  }

  void stopObserving() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _expiryCheckTimer?.cancel();
  }

  Future<int> _appLockTimeoutSeconds(PreferenceManager pref) async {
    final seconds = await pref.getInt(
      PreferenceManager.keyAppLockTimeoutSeconds,
      defaultValue: 300,
    );
    return seconds > 0 ? seconds : 300;
  }

  Future<void> _saveBackgroundedAt(DateTime pausedAt) async {
    try {
      final pref = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      await pref.setInt(
        PreferenceManager.keyAppBackgroundedAtMs,
        pausedAt.millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> _startTimer() async {
    _timer?.cancel();
    final pref = Get.find<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    );
    final timeoutSeconds = await _appLockTimeoutSeconds(pref);
    if (!_isPaused) return;

    _timer = Timer(Duration(seconds: timeoutSeconds), () {
      debugPrint('App has been in the background for $timeoutSeconds seconds.');
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
