import 'dart:convert';

import 'exchange_rate.dart';

class FxResponse {
  FxResponse({
    this.responseCode,
    this.message,
    this.rates = const [],
  });

  final String? responseCode;
  final String? message;
  final List<ExchangeRate> rates;

  bool get isSuccess {
    final c = responseCode?.trim();
    return c == '0' || c == '200' || c == '201';
  }

  factory FxResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return FxResponse();
    }
    final m = Map<String, dynamic>.from(json);
    return FxResponse(
      responseCode: m['responseCode']?.toString(),
      message: m['message']?.toString(),
      rates: _parseRates(m['rates']),
    );
  }

  static List<ExchangeRate> _parseRates(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ExchangeRate.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.currency.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _parseRates(decoded);
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }
}
