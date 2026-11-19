import 'dart:convert';

import '../../modules/add_listing/models/apartment_unit_draft.dart';

/// Rent stored on the parent property row in the remote `properties` table.
///
/// A single unit keeps the amount the host entered. Several units store the
/// sum of monthly rent for rent-mode units. A multi-unit property with no
/// rent units (BnB only) stores an empty amount.
class PropertyRemoteRent {
  PropertyRemoteRent._();

  static String amount({
    required int unitCount,
    required String listingRentAmount,
    required String unitsJson,
  }) {
    final drafts = _drafts(unitsJson);
    final count = unitCount > 1
        ? unitCount
        : (drafts.length > 1 ? drafts.length : unitCount);
    if (count <= 1) return listingRentAmount.trim();
    final sum = _monthlySum(drafts);
    if (sum <= 0) return '';
    if ((sum - sum.roundToDouble()).abs() < 0.001) {
      return sum.round().toString();
    }
    return sum.toStringAsFixed(2);
  }

  /// When [amount] is a monthly sum, the frequency on the property row is
  /// Per Month. A single unit keeps the frequency the host chose.
  static String frequency({
    required int unitCount,
    required String listingRentFrequency,
    required String unitsJson,
    required String rentAmount,
  }) {
    final drafts = _drafts(unitsJson);
    final count = unitCount > 1
        ? unitCount
        : (drafts.length > 1 ? drafts.length : unitCount);
    if (count > 1 && rentAmount.trim().isNotEmpty) return 'Per Month';
    return listingRentFrequency;
  }

  static List<ApartmentUnitDraft> _drafts(String unitsJson) {
    final raw = unitsJson.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static double _monthlySum(List<ApartmentUnitDraft> drafts) {
    var sum = 0.0;
    for (final unit in drafts) {
      final mode = ApartmentUnitDraft.resolveOperationMode(
        unit.operationMode,
        unit.unitRentFrequency,
      );
      if (mode != 'rent') continue;
      final rent = double.tryParse(unit.unitRent.replaceAll(',', '').trim());
      if (rent == null || rent <= 0) continue;
      sum += _toMonthly(rent, unit.unitRentFrequency);
    }
    return sum;
  }

  static double _toMonthly(double amount, String frequency) {
    final freq = frequency.trim().toLowerCase();
    if (freq.contains('week')) return amount * 52 / 12;
    if (freq.contains('year') || freq.contains('annual')) return amount / 12;
    if (freq.contains('quarter')) return amount / 3;
    if (freq.contains('day')) return amount * 30;
    return amount;
  }
}
