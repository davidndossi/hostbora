import 'package:get/get.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../../l10n/app_localizations_sw.dart';
import 'app_locale_controller.dart';

/// Resolves [AppLocalizations] for the active app language.
///
/// Prefer this over `AppLocalizations.of(Get.context!)` when showing alerts /
/// validation after a language change — [Get.context] can still hold the
/// previous localization delegate until the next full MaterialApp rebuild.
AppLocalizations resolveAppLocalizations() {
  final fromContext =
      Get.context != null ? AppLocalizations.of(Get.context!) : null;
  final wantSw = Get.isRegistered<AppLocaleController>()
      ? Get.find<AppLocaleController>().isSw
      : Get.locale?.languageCode == 'sw';
  if (fromContext != null) {
    final contextIsSw = fromContext.localeName.toLowerCase().startsWith('sw');
    if (contextIsSw == wantSw) return fromContext;
  }
  return wantSw ? AppLocalizationsSw() : AppLocalizationsEn();
}

bool isAppLanguageSw() {
  if (Get.isRegistered<AppLocaleController>()) {
    return Get.find<AppLocaleController>().isSw;
  }
  return Get.locale?.languageCode == 'sw';
}
