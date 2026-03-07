import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';

const String _keyDarkTheme = 'is_dark_theme';

class ThemeController extends GetxController {
  ThemeController(this._preferenceManager);

  final PreferenceManager _preferenceManager;

  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final dark = await _preferenceManager.getBool(_keyDarkTheme, defaultValue: false);
    isDarkMode.value = dark;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _preferenceManager.setBool(_keyDarkTheme, isDarkMode.value);
  }
}
