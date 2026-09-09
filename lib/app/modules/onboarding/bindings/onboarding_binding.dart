import 'package:get/get.dart';

import '../../../data/local/service/currency_service.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    // Onboarding shows BaseCurrencyPicker; ensure CurrencyService exists
    // even if InitialBinding's async path was skipped or raced.
    if (!Get.isRegistered<CurrencyService>()) {
      final currency = Get.put<CurrencyService>(
        CurrencyService(),
        permanent: true,
      );
      currency.init();
    }
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(),
      fenix: true,
    );
  }
}
