import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../l10n/app_localizations.dart';
import '/app/bindings/initial_binding.dart';
import '/app/core/theme/theme_controller.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/values/app_values.dart';
import '/app/routes/app_pages.dart';
import '/flavors/build_config.dart';
import '/flavors/env_config.dart';
import 'core/base/app_lifecycle_manager.dart';
import 'data/local/preference/preference_manager.dart';
import 'data/local/preference/preference_manager_impl.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late String _lang;
  late String _countryCode;
  late AppLifecycleManager _lifecycleManager;

  bool _isLoggedIn = false;
  bool _hasValidPin = false;
  bool _hasSeenOnboarding = true; // default true so we don't block on first run
  bool _loading = true;

  final PreferenceManager _preferenceManager = Get.put<PreferenceManager>(
    PreferenceManagerImpl(),
    tag: (PreferenceManager).toString(),
  );
  final EnvConfig _envConfig = BuildConfig.instance.config;

  Future<void> loadLanguage() async {
    _lang = await _preferenceManager.getString('language', defaultValue: 'en');
    _countryCode = _lang == 'en' ? 'US' : 'TZ';
  }

  Future<bool> isSessionValid() async {
    final accessToken = await _preferenceManager.getString(
      'token',
      defaultValue: '',
    );
    final expiryTime = await _preferenceManager.getString(
      'expiry_time',
      defaultValue: '',
    );

    if (accessToken == '' || expiryTime == '') return false;

    int expiryTimeDt;
    try {
      expiryTimeDt = DateTime.parse(expiryTime).millisecondsSinceEpoch;
    } on Exception catch (_, e) {
      e.printError(info: 'Failed to parse date');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return now <= expiryTimeDt; // true if not expired
  }

  static const _bootstrapTimeout = Duration(seconds: 10);

  Future<void> _bootstrap() async {
    try {
      await loadLanguage().timeout(_bootstrapTimeout);
      final results = await Future.wait([
        isSessionValid().timeout(_bootstrapTimeout),
        _preferenceManager
            .getBool('seen_onboarding', defaultValue: false)
            .timeout(_bootstrapTimeout),
        _preferenceManager
            .getBool(PreferenceManager.keyPinEnabled, defaultValue: false)
            .timeout(_bootstrapTimeout),
        _preferenceManager
            .getString(PreferenceManager.keyPinCode, defaultValue: '')
            .timeout(_bootstrapTimeout),
      ]);
      final loggedIn = results[0] as bool;
      final hasSeenOnboarding = results[1] as bool;
      final pinEnabled = results[2];
      final pinCode = results[3] as String;
      final hasValidPin = (pinEnabled as bool) && pinCode.length == 4;

      if (!mounted) return;

      setState(() {
        _isLoggedIn = loggedIn;
        _hasSeenOnboarding = hasSeenOnboarding;
        _hasValidPin = hasValidPin;
        _loading = false;
      });
    } catch (e, stack) {
      if (BuildConfig.instance.config.shouldCollectCrashLog) {
        BuildConfig.instance.config.logger.e(
          'Bootstrap failed',
          error: e,
          stackTrace: stack,
        );
      }
      if (!mounted) return;
      setState(() {
        _lang = 'en';
        _countryCode = 'US';
        _isLoggedIn = false;
        _hasSeenOnboarding = true; // on error, skip onboarding to avoid loop
        _hasValidPin = false;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _lifecycleManager = AppLifecycleManager(context);
    _lifecycleManager.startObserving();

    _lang = 'en';
    _countryCode = 'US';

    // Run bootstrap after the first frame so the loading screen paints and replaces the native splash.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.colorPrimary),
          useMaterial3: false,
        ),
        home: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.colorPrimary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _lang == 'sw' ? 'Inapakia...' : 'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textColorSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(
        ThemeController(_preferenceManager),
        permanent: true,
      );
    }
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: _envConfig.appName,
        initialRoute: _hasSeenOnboarding
            ? (_isLoggedIn
                  ? (_hasValidPin ? Routes.WELCOME_BACK : Routes.CHANGE_PIN)
                  : (_hasValidPin ? Routes.WELCOME_BACK : AppPages.auth))
            : Routes.ONBOARDING,
        initialBinding: InitialBinding(),
        getPages: AppPages.routes,
        locale: Locale(_lang, _countryCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: _getSupportedLocal(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  static const TextStyle _buttonTextStyle = TextStyle(fontSize: 16);

  static ThemeData _lightTheme() {
    return ThemeData(
      primarySwatch: AppColors.colorPrimarySwatch,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: Brightness.light,
      primaryColor: AppColors.colorPrimary,
      scaffoldBackgroundColor: AppColors.pageBackground,
      cardColor: AppColors.colorWhite,
      useMaterial3: false,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorPrimary,
          foregroundColor: AppColors.textColorWhite,
          minimumSize: const Size.fromHeight(AppValues.formButtonHeight),
          textStyle: _buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.colorWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(color: AppColors.designInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(
            color: AppColors.colorPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        labelStyle: const TextStyle(color: AppColors.designPlaceholder),
      ),
      textTheme: const TextTheme(
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android: black icons
          statusBarBrightness: Brightness.light, // iOS: black icons
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.appBarTextColor,
          fontFamily: 'Roboto',
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  static ThemeData _darkTheme() {
    const darkBackground = Color(0xFF1C1C1E);
    const darkCard = Color(0xFF2C2C2E);
    return ThemeData(
      primarySwatch: AppColors.colorPrimarySwatch,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: Brightness.dark,
      primaryColor: AppColors.colorPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      useMaterial3: false,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorPrimary,
          foregroundColor: AppColors.textColorWhite,
          minimumSize: const Size.fromHeight(AppValues.formButtonHeight),
          textStyle: _buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(textStyle: _buttonTextStyle),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(
            color: AppColors.colorPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_6),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android: black icons
          statusBarBrightness: Brightness.light, // iOS: black icons
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textColorWhite,
          fontFamily: 'Roboto',
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  @override
  void dispose() {
    _lifecycleManager.stopObserving();
    super.dispose();
  }

  List<Locale> _getSupportedLocal() {
    return [const Locale('en', 'US'), const Locale('sw', 'TZ')];
  }
}
