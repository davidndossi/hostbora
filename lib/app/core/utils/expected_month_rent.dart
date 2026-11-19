import 'dart:convert';

import '../../data/local/db/property_local_data_source.dart';
import '../../data/local/db/tenant_local_data_source.dart';

/// Nightly price of one BnB unit, in that unit's currency.
class BnbUnitRate {
  const BnbUnitRate({
    required this.unitId,
    required this.unitName,
    required this.nightlyAmount,
    required this.currency,
  });

  final String unitId;
  final String unitName;
  final double nightlyAmount;
  final String currency;

  bool matchesTenant(TenantRecord tenant) {
    final id = tenant.apartmentUnitId.trim();
    final name = tenant.unitLabel.trim().toLowerCase();
    if (unitId.isNotEmpty && id.isNotEmpty && unitId == id) return true;
    if (unitName.isNotEmpty &&
        name.isNotEmpty &&
        unitName.toLowerCase() == name) {
      return true;
    }
    return false;
  }
}

/// This calendar month's rent for one tenant. Home and property details share
/// this so the portfolio Expected figure is the sum of each property's figure.
///
/// A BnB unit is not prorated by the stay. Its expected income is the nightly
/// amount, converted to the base currency, times the number of days in the month.
abstract final class ExpectedMonthRent {
  static double of(
    TenantRecord tenant, {
    required DateTime monthStart,
    required DateTime nextMonthStart,
  }) {
    if (tenant.rentAmountValue <= 0) return 0;

    final freq = tenant.rentFrequency.trim().toLowerCase();
    final isPerNight = freq.contains('night');
    final isWeekly = freq.contains('week');
    final isYearly = freq.contains('year') || freq.contains('annual');

    if (isPerNight || isWeekly || isYearly) {
      final start = _parseCalendarDay(tenant.leaseStartIso.trim());
      if (start == null) return 0;

      final overlapStart = start.isBefore(monthStart) ? monthStart : start;

      DateTime overlapEnd;
      final endRaw = tenant.leaseEndIso.trim();
      if (endRaw.isEmpty) {
        overlapEnd = nextMonthStart;
      } else {
        final end = _parseCalendarDay(endRaw);
        if (end == null) {
          overlapEnd = nextMonthStart;
        } else {
          final endPlusOne = end.add(const Duration(days: 1));
          overlapEnd =
              endPlusOne.isBefore(nextMonthStart) ? endPlusOne : nextMonthStart;
        }
      }

      final overlapDays = overlapEnd.difference(overlapStart).inDays;
      if (overlapDays <= 0) return 0;
      if (isPerNight) return tenant.rentAmountValue * overlapDays;
      if (isWeekly) return (tenant.rentAmountValue / 7) * overlapDays;
      return (tenant.rentAmountValue / 365) * overlapDays;
    }

    if (freq.contains('stay')) {
      final start = _parseCalendarDay(tenant.leaseStartIso.trim());
      if (start != null && !start.isBefore(nextMonthStart)) return 0;
      final end = _parseCalendarDay(tenant.leaseEndIso.trim());
      if (end != null && end.isBefore(monthStart)) return 0;
      return tenant.rentAmountValue;
    }

    // Monthly, and per day: one full period while the stay has started.
    final start = _parseCalendarDay(tenant.leaseStartIso.trim());
    if (start != null && !start.isBefore(nextMonthStart)) return 0;
    return tenant.rentAmountValue;
  }

  static int daysInMonth(DateTime monthStart) {
    final start = DateTime(monthStart.year, monthStart.month, 1);
    final next = DateTime(monthStart.year, monthStart.month + 1, 1);
    return next.difference(start).inDays;
  }

  /// BnB units on [property]. A BnB property with no stored unit list counts
  /// as one unit priced from the property rent.
  static List<BnbUnitRate> bnbUnitsOf(
    PropertyRecord property, {
    required int daysInMonth,
  }) {
    final workspace = property.workspaceType.trim().toLowerCase();
    final fromJson = _unitsFromJson(property.unitsJson);
    if (fromJson.isEmpty) {
      if (workspace != 'bnb') return const [];
      final rent = double.tryParse(property.rentAmount.replaceAll(',', '').trim());
      final nightly = nightlyFrom(rent ?? 0, property.rentFrequency, daysInMonth);
      if (nightly == null || nightly <= 0) return const [];
      final name = property.propertyName.trim().isNotEmpty
          ? property.propertyName.trim()
          : property.propertyLocation.trim();
      return [
        BnbUnitRate(
          unitId: 'main',
          unitName: name,
          nightlyAmount: nightly,
          currency: '',
        ),
      ];
    }

    final units = <BnbUnitRate>[];
    for (final entry in fromJson) {
      if (!_isBnbUnit(entry, workspace)) continue;
      final amount = double.tryParse(
            (entry['unitRent'] ?? entry['rent'] ?? entry['price'] ?? '')
                .toString()
                .replaceAll(',', '')
                .trim(),
          ) ??
          0;
      final frequency =
          (entry['unitRentFrequency'] ?? entry['rentFrequency'] ?? '')
              .toString();
      final nightly = nightlyFrom(amount, frequency, daysInMonth) ??
          (amount > 0 ? amount : 0);
      final currency =
          (entry['unitRentCurrency'] ?? entry['rentCurrency'] ?? entry['currency'] ?? '')
              .toString()
              .trim();
      units.add(
        BnbUnitRate(
          unitId: (entry['unitId'] ?? entry['id'] ?? '').toString().trim(),
          unitName: (entry['unitName'] ?? entry['name'] ?? '').toString().trim(),
          nightlyAmount: nightly,
          currency: currency,
        ),
      );
    }
    return units;
  }

  /// True when every tenant on this property is already represented by a BnB unit.
  static bool bnbUnitsCoverAllTenants(PropertyRecord property) {
    final workspace = property.workspaceType.trim().toLowerCase();
    final units = _unitsFromJson(property.unitsJson);
    if (workspace == 'rent') return false;
    if (units.isEmpty) return workspace == 'bnb';
    return units.every((entry) => _isBnbUnit(entry, workspace));
  }

  static bool tenantOnProperty(TenantRecord tenant, PropertyRecord property) {
    final ref = tenant.propertyRef.trim();
    if (ref.isEmpty) return false;
    final hub = property.propertyRef.trim();
    return ref == hub ||
        ref == 'local_${property.id}' ||
        ref == 'legacy_${property.id}';
  }

  /// Amount charged for one night, in the same currency as [amount].
  static double? nightlyFrom(double amount, String frequency, int daysInMonth) {
    if (amount <= 0) return null;
    final value = frequency.trim().toLowerCase();
    if (value.contains('stay')) return null;
    if (value.contains('night') || value.contains('day')) return amount;
    if (value.contains('week')) return amount / 7;
    if (value.contains('year') || value.contains('annual')) return amount / 365;
    if (value.contains('month')) {
      if (daysInMonth <= 0) return null;
      return amount / daysInMonth;
    }
    return amount;
  }

  static List<Map<String, dynamic>> _unitsFromJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static bool _isBnbUnit(Map<String, dynamic> unit, String workspace) {
    final mode = (unit['operationMode'] ?? '').toString().trim().toLowerCase();
    if (mode == 'rent') return false;
    if (mode == 'bnb') return true;
    if (workspace == 'rent') return false;
    if (workspace == 'bnb') return true;
    final frequency = (unit['unitRentFrequency'] ?? '').toString().toLowerCase();
    return frequency.contains('night') ||
        frequency.contains('day') ||
        frequency.contains('stay');
  }

  static DateTime? _parseCalendarDay(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
      if (y != null &&
          m != null &&
          m >= 1 &&
          m <= 12 &&
          d != null &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
