class ExchangeRate {
  const ExchangeRate({
    required this.currency,
    required this.buying,
    required this.selling,
  });

  final String currency;
  final double buying;
  final double selling;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      currency: (json['currency'] ?? '').toString().trim().toUpperCase(),
      buying: _toDouble(json['buying']),
      selling: _toDouble(json['selling']),
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'buying': buying,
        'selling': selling,
      };

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;
  }
}
