class LukuSmsTopUpDraft {
  const LukuSmsTopUpDraft({
    required this.token,
    required this.unitsKwh,
    required this.meterNumber,
    required this.amountTsh,
    required this.date,
  });

  final String token;
  final double unitsKwh;
  final String meterNumber;
  final double amountTsh;
  final DateTime date;

  String get notes {
    final tokenLabel = _groupDigits(token);
    final parts = <String>[
      if (meterNumber.isNotEmpty) 'Meter $meterNumber',
      if (tokenLabel.isNotEmpty) 'Token $tokenLabel',
    ];
    return parts.join(' • ');
  }

  static String _groupDigits(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final chunks = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      final end = i + 4 > digits.length ? digits.length : i + 4;
      chunks.add(digits.substring(i, end));
    }
    return chunks.join(' ');
  }
}

class LukuSmsOcrParser {
  const LukuSmsOcrParser();

  static const _months = <String, int>{
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  List<LukuSmsTopUpDraft> parse(String rawText, {DateTime? now}) {
    final normalized = _normalizeText(rawText);
    if (normalized.isEmpty) return const [];

    final referenceDate = now ?? DateTime.now();
    final matches = _messagePattern.allMatches(normalized);
    final drafts = <LukuSmsTopUpDraft>[];

    for (final match in matches) {
      final token = _digitsOnly(match.group(1) ?? '');
      final units = _parseNumber(match.group(2));
      final meter = _digitsOnly(match.group(3) ?? '');
      final amount = _parseNumber(match.group(4));
      if (token.isEmpty || units == null || meter.isEmpty || amount == null) {
        continue;
      }

      drafts.add(
        LukuSmsTopUpDraft(
          token: token,
          unitsKwh: units,
          meterNumber: meter,
          amountTsh: amount,
          date: _dateBefore(normalized, match.start, referenceDate),
        ),
      );
    }

    return drafts;
  }

  String _normalizeText(String rawText) {
    return rawText
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
  }

  DateTime _dateBefore(String text, int offset, DateTime now) {
    final prefix = text.substring(0, offset);
    final dateMatches = _datePattern.allMatches(prefix);
    final latest = dateMatches.isEmpty ? null : dateMatches.last;
    if (latest == null) return now;

    final day = int.tryParse(latest.group(1) ?? '');
    final month = _months[(latest.group(2) ?? '').toLowerCase()];
    final hour = int.tryParse(latest.group(3) ?? '');
    final minute = int.tryParse(latest.group(4) ?? '');
    if (day == null || month == null || hour == null || minute == null) {
      return now;
    }

    var parsed = DateTime(now.year, month, day, hour, minute);
    if (parsed.isAfter(now.add(const Duration(days: 1)))) {
      parsed = DateTime(now.year - 1, month, day, hour, minute);
    }
    return parsed;
  }

  static final _messagePattern = RegExp(
    r'LUKU\s+Token\s+(.+?)\s*,\s*Units?\s*([0-9]+(?:[.,][0-9]+)?)\s*KWH\s*,\s*Meter\s+No\.?\s*([0-9 ]+)\s*,\s*TZS\s*([0-9][0-9,.]*)',
    caseSensitive: false,
    dotAll: true,
  );

  static final _datePattern = RegExp(
    r'(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s+(\d{1,2})\s+([A-Za-z]{3,9})\s+at\s+(\d{1,2}):(\d{2})',
    caseSensitive: false,
  );

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static double? _parseNumber(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }
}
