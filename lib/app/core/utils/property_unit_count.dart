import 'dart:convert';

import '../../data/local/db/property_local_data_source.dart';

/// Shared rules for counting rentable units on a [PropertyRecord].
///
/// Prefer the numeric [PropertyRecord.units] column when set (matches the API /
/// online DB). Fall back to structured [PropertyRecord.unitsJson] for local-only
/// drafts. Never invent a unit when both are empty.
abstract class PropertyUnitCount {
  PropertyUnitCount._();

  static int of(PropertyRecord p) {
    if (p.units > 0) return p.units;
    return fromUnitsJson(p.unitsJson);
  }

  static int fromUnitsJson(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text == '[]' || text == 'null') return 0;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return 0;
      var count = 0;
      for (final item in decoded) {
        if (item is Map) {
          final name = (item['unitName'] ?? item['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
        }
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}
