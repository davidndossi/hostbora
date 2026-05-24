import 'package:get/get.dart';

import '../../data/local/service/currency_service.dart';

/// Parses amount text and converts to base currency for persistence.
class MoneyInputHelper {
  MoneyInputHelper._();

  static double parseRaw(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '')) ?? 0;
  }

  static ({double baseAmount, double inputAmount, String currency}) forSave({
    required String amountRaw,
    required String selectedCurrency,
  }) {
    final input = parseRaw(amountRaw);
    final currency = selectedCurrency.trim().toUpperCase();
    final svc = Get.find<CurrencyService>();
    final base = svc.toBaseAmount(
      inputAmount: input,
      inputCurrency: currency.isEmpty ? svc.baseCurrency.value : currency,
    );
    return (baseAmount: base, inputAmount: input, currency: currency);
  }
}
