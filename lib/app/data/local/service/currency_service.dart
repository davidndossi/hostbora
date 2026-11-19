import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/exchange_rate.dart';
import '../../model/update_preference_request.dart';
import '../../repository/app_repository.dart';
import '../db/exchange_rate_local_data_source.dart';
import '../preference/preference_manager.dart';

/// Base currency, FX rates, conversion (selling rate), and display formatting.
class CurrencyService extends GetxService {
  CurrencyService({
    PreferenceManager? preferenceManager,
    ExchangeRateLocalDataSource? exchangeRateLocal,
    AppRepository? repository,
  }) : _preferenceManager =
           preferenceManager ??
           Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
       _exchangeRateLocal =
           exchangeRateLocal ?? Get.find<ExchangeRateLocalDataSource>(),
       _repository =
           repository ??
           Get.find<AppRepository>(tag: (AppRepository).toString());

  static const defaultBaseCurrency = 'TZS';

  /// Static list for pickers (onboarding, settings) — no network required.
  static const List<String> supportedBaseCurrencies = [
    'TZS',
    'USD',
    'EUR',
    'GBP',
    'KES',
    'UGX',
    'RWF',
    'ZAR',
    'CNY',
    'INR',
    'AED',
    'CAD',
    'AUD',
  ];

  final PreferenceManager _preferenceManager;
  final ExchangeRateLocalDataSource _exchangeRateLocal;
  final AppRepository _repository;

  final baseCurrency = defaultBaseCurrency.obs;
  final rates = <ExchangeRate>[].obs;
  final loadingRates = false.obs;

  Future<CurrencyService> init() async {
    final saved = await _preferenceManager.getString(
      PreferenceManager.keyBaseCurrency,
      defaultValue: defaultBaseCurrency,
    );
    baseCurrency.value = saved.trim().isEmpty
        ? defaultBaseCurrency
        : saved.trim().toUpperCase();
    await _loadRatesFromLocal();
    unawaited(refreshRatesFromRemote());
    return this;
  }

  Future<void> _loadRatesFromLocal() async {
    final rows = await _exchangeRateLocal.getAll();
    rates.assignAll(_ensureBaseInList(rows));
  }

  List<ExchangeRate> _ensureBaseInList(List<ExchangeRate> list) {
    final codes = list.map((e) => e.currency).toSet();
    final base = baseCurrency.value;
    if (!codes.contains(base)) {
      return [ExchangeRate(currency: base, buying: 1, selling: 1), ...list];
    }
    return list;
  }

  /// Fetches from API, persists locally, refreshes [rates].
  Future<bool> refreshRatesFromRemote() async {
    loadingRates.value = true;
    try {
      final response = await _repository.getExchangeRates();
      if (!response.isSuccess || response.rates.isEmpty) {
        return false;
      }
      await _exchangeRateLocal.replaceAll(response.rates);
      rates.assignAll(_ensureBaseInList(response.rates));
      return true;
    } catch (_) {
      return false;
    } finally {
      loadingRates.value = false;
    }
  }

  Future<void> setBaseCurrency(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    baseCurrency.value = c;
    await _preferenceManager.setString(PreferenceManager.keyBaseCurrency, c);
    rates.assignAll(_ensureBaseInList(rates.toList()));
    unawaited(_syncBaseCurrencyRemote(c));
  }

  Future<void> _syncBaseCurrencyRemote(String code) async {
    try {
      await _repository.updateSettingsPreferences(
        UpdatePreferenceRequest(baseCurrency: code),
      );
    } catch (_) {
      // Local preference is source of truth offline; sync is best-effort.
    }
  }

  List<String> get currencyCodes {
    if (rates.isEmpty) {
      return List<String>.from(supportedBaseCurrencies);
    }
    final codes = rates.map((r) => r.currency).toSet().toList()..sort();
    for (final c in supportedBaseCurrencies) {
      if (!codes.contains(c)) codes.add(c);
    }
    codes.sort();
    if (!codes.contains(baseCurrency.value)) {
      codes.insert(0, baseCurrency.value);
    }
    return codes;
  }

  /// Picker-only list — always static, never blocked on FX fetch.
  List<String> get pickerCurrencyCodes => List<String>.from(supportedBaseCurrencies);

  double? sellingRateFor(String currency) {
    final c = currency.trim().toUpperCase();
    if (c.isEmpty || c == 'TZS') return 1;
    for (final r in rates) {
      if (r.currency == c && r.selling > 0) return r.selling;
    }
    return null;
  }

  /// Converts [inputAmount] in [inputCurrency] to [baseCurrency] using selling rates.
  /// Rates are TZS per 1 unit of foreign currency; pivots through TZS when needed.
  double toBaseAmount({
    required double inputAmount,
    required String inputCurrency,
  }) {
    if (inputAmount <= 0) return 0;
    final from = inputCurrency.trim().toUpperCase();
    final base = baseCurrency.value;
    if (from.isEmpty || from == base) return inputAmount;

    final fromSelling = sellingRateFor(from);
    if (fromSelling == null || fromSelling <= 0) {
      // Missing FX rate — avoid treating foreign amount as base (e.g. USD→TZS * 1).
      return inputAmount;
    }
    final baseSelling = base == 'TZS' ? 1.0 : (sellingRateFor(base) ?? 0);
    if (base != 'TZS' && (baseSelling <= 0)) return inputAmount;

    final inTzs = from == 'TZS' ? inputAmount : inputAmount * fromSelling;
    if (base == 'TZS') return inTzs;
    return inTzs / baseSelling;
  }

  /// Formats [amount] of [fromCurrency] in the user's base currency.
  ///
  /// A USD price shown to a TZS user becomes the shilling equivalent. When the
  /// rate is not loaded yet, the original currency is shown instead of a
  /// number wearing the wrong symbol.
  String formatMoneyInBase({
    required double amount,
    required String fromCurrency,
    String suffix = '',
  }) {
    final from = fromCurrency.trim().toUpperCase();
    final base = baseCurrency.value;
    rates.length;
    if (from.isEmpty || from == base || _canConvert(from, base)) {
      final converted = from.isEmpty || from == base
          ? amount
          : toBaseAmount(inputAmount: amount, inputCurrency: from);
      return '${formatBase(converted, decimalDigits: _displayDigits(base))}$suffix';
    }
    final digits = _displayDigits(from);
    final fmt = NumberFormat.currency(
      symbol: symbolFor(from),
      decimalDigits: digits,
      name: from,
    );
    return '${fmt.format(amount)}$suffix';
  }

  bool _canConvert(String from, String base) {
    if (from == base) return true;
    if (from != 'TZS' && sellingRateFor(from) == null) return false;
    if (base != 'TZS' && sellingRateFor(base) == null) return false;
    return true;
  }

  int _displayDigits(String code) {
    switch (code) {
      case 'TZS':
      case 'UGX':
      case 'RWF':
        return 0;
      default:
        return 2;
    }
  }

  String formatBase(num amount, {int decimalDigits = 0}) {
    final code = baseCurrency.value;
    final symbol = symbolFor(code);
    final fmt = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      name: code,
    );
    return fmt.format(amount);
  }

  String formatBaseCompact(num amount) {
    final rounded = amount.round();
    return '${symbolFor(baseCurrency.value)}${NumberFormat('#,###', 'en_US').format(rounded)}';
  }

  /// Large amounts: 1.2M, 50K, else full [formatBase].
  String formatBaseShort(num amount) {
    final v = amount.round();
    final sym = symbolFor(baseCurrency.value).trim();
    if (v.abs() >= 1000000) {
      return '$sym ${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v.abs() >= 1000) {
      return '$sym ${(v / 1000).toStringAsFixed(0)}K';
    }
    return formatBase(v);
  }

  /// Digits only — use with [formatBase] or [inputPrefix] when splitting label/prefix.
  String formatNumber(num amount) =>
      NumberFormat('#,###', 'en_US').format(amount.round());

  /// TextField prefix (symbol + space).
  String get inputPrefix => symbolFor(baseCurrency.value);

  /// Suffix code for compact fields (e.g. loyalty threshold).
  String get inputSuffix => baseCurrency.value;

  static String zeroLabel() {
    if (Get.isRegistered<CurrencyService>()) {
      return Get.find<CurrencyService>().formatBase(0);
    }
    return '0';
  }

  static String symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'TZS':
        return 'Tsh ';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'KES':
        return 'KES ';
      default:
        return '$code ';
    }
  }

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<CurrencyService>()) return;
    await Get.find<CurrencyService>()._loadRatesFromLocal();
  }
}
