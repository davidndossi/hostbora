import 'dart:async';

import 'package:get/get.dart';

import '../db/property_local_data_source.dart';
import '../preference/preference_manager.dart';

/// Bottom-nav property count. Starts at 0 so first paint is never blocked;
/// SQL COUNT runs off the UI isolate queue and Obx updates the badge later.
class PropertyCountStore extends GetxService {
  PropertyCountStore({
    PropertyLocalDataSource? propertyLocal,
    PreferenceManager? preferenceManager,
  }) : _propertyLocal = propertyLocal,
       _preferenceManager = preferenceManager;

  PropertyLocalDataSource? _propertyLocal;
  PreferenceManager? _preferenceManager;

  final count = 0.obs;
  int _seq = 0;
  Timer? _debounce;

  static String? labelFor(int n) {
    if (n <= 0) return null;
    if (n > 99) return '99+';
    return '$n';
  }

  String? get badgeLabel => labelFor(count.value);

  @override
  void onInit() {
    super.onInit();
    PropertyLocalDataSource.addOnChangedListener(scheduleRefresh);
    scheduleRefresh();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    PropertyLocalDataSource.removeOnChangedListener(scheduleRefresh);
    super.onClose();
  }

  void scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 40), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    try {
      final prefs = _resolvePrefs();
      var userId = '';
      if (prefs != null) {
        userId = ((await prefs.getUser()).id ?? '').trim();
      }
      if (userId.isEmpty) {
        if (seq != _seq) return;
        if (count.value != 0) count.value = 0;
        return;
      }
      final local = _resolveLocal();
      if (local == null) return;
      final n = await local.countVisibleForUser(userId);
      if (seq != _seq) return;
      if (count.value != n) count.value = n;
    } catch (_) {
      // Keep the last painted count (0 on first frame).
    }
  }

  PreferenceManager? _resolvePrefs() {
    if (_preferenceManager != null) return _preferenceManager;
    if (!Get.isRegistered<PreferenceManager>(
      tag: (PreferenceManager).toString(),
    )) {
      return null;
    }
    return Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
  }

  PropertyLocalDataSource? _resolveLocal() {
    if (_propertyLocal != null) return _propertyLocal;
    if (!Get.isRegistered<PropertyLocalDataSource>()) return null;
    return Get.find<PropertyLocalDataSource>();
  }
}
