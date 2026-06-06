import 'package:get/get.dart';

import '../../data/local/service/currency_service.dart';

class CurrencyConversionException implements Exception {
  const CurrencyConversionException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
    final from = currency.isEmpty ? svc.baseCurrency.value : currency;
    final baseCurrency = svc.baseCurrency.value;
    if (input > 0 && from != baseCurrency) {
      if (from != 'TZS' && svc.sellingRateFor(from) == null) {
        throw CurrencyConversionException(
          'Missing selling rate for $from. Refresh exchange rates and try again.',
        );
      }
      if (baseCurrency != 'TZS' && svc.sellingRateFor(baseCurrency) == null) {
        throw CurrencyConversionException(
          'Missing selling rate for $baseCurrency. Refresh exchange rates and try again.',
        );
      }
    }
    final convertedBaseAmount = svc.toBaseAmount(
      inputAmount: input,
      inputCurrency: from,
    );
    return (
      baseAmount: convertedBaseAmount,
      inputAmount: input,
      currency: from,
    );
  }
}
