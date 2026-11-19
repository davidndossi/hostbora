import '../../../core/values/property_unit_floor.dart';

/// One apartment unit row added from the “Add Unit” flow.
/// [unitId] is stable in [units_json] so tenants can link via [RentTenantRecord.apartmentUnitId].
class ApartmentUnitDraft {
  const ApartmentUnitDraft({
    this.unitId = '',
    required this.unitName,
    required this.unitRent,
    this.unitRentFrequency = 'Per Day',
    this.unitFloor = PropertyUnitFloor.defaultIndex,
    this.operationMode = 'bnb',
    required this.unitDescription,
    this.unitRentCurrency = 'TZS',
  });

  /// `u_<stamp>_<floor>` — stamp is microseconds (or a property/listing id),
  /// floor is the [PropertyUnitFloor] index. Same string is stored as
  /// `property_units.property_unit_ref`.
  static String newRef({int? floor, String? stamp}) {
    final f = PropertyUnitFloor.parse(floor);
    final mid = (stamp ?? DateTime.now().microsecondsSinceEpoch.toString())
        .trim();
    return 'u_${mid}_$f';
  }

  /// Persistent id (saved on the parent property). Empty for legacy rows until re-saved.
  final String unitId;
  final String unitName;
  final String unitRent;

  /// Same labels as listing [rentFrequency] (e.g. Per Day).
  final String unitRentFrequency;

  /// [PropertyUnitFloor] index (0 = ground).
  final int unitFloor;

  /// Unit workspace mode. For a `both` property, each unit must be either `bnb` or `rent`.
  final String operationMode;

  /// Optional; may be empty.
  final String unitDescription;

  /// ISO 4217 currency code for [unitRent]. Always the contract currency; convert at display time.
  final String unitRentCurrency;

  /// Key for dropdowns when [unitId] is missing (legacy JSON).
  String get selectionKey =>
      unitId.trim().isNotEmpty ? unitId.trim() : '__n:${unitName.trim()}';

  Map<String, dynamic> toJson() => {
    'unitId': unitId.trim(),
    'unitName': unitName,
    'unitRent': unitRent,
    'unitRentFrequency': unitRentFrequency,
    'unitFloor': unitFloor,
    'operationMode': operationMode,
    'unitDescription': unitDescription,
    'unitRentCurrency': unitRentCurrency,
  };

  static const minDurationRent = '1 Month';
  static const minDurationBnb = '1 Day';

  /// Rent units stay at least a month. BnB units stay at least a night.
  static String minDurationForMode(String? mode, {String frequency = ''}) {
    return resolveOperationMode(mode ?? '', frequency) == 'rent'
        ? minDurationRent
        : minDurationBnb;
  }

  /// Same rule as listing details: an explicit mode wins. Otherwise a monthly,
  /// weekly, yearly, or quarterly rate is a rent unit.
  static String resolveOperationMode(String mode, String frequency) {
    final raw = mode.trim().toLowerCase();
    if (raw == 'rent' || raw == 'bnb') return raw;
    final freq = frequency.trim().toLowerCase();
    if (freq.contains('month') ||
        freq.contains('week') ||
        freq.contains('year') ||
        freq.contains('quarter')) {
      return 'rent';
    }
    return 'bnb';
  }

  static String _firstText(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final value = m[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  factory ApartmentUnitDraft.fromJson(Map<String, dynamic> m) {
    final freq = _firstText(m, const ['unitRentFrequency']);
    final mode = _firstText(m, const ['operationMode']);
    final currency = _firstText(m, const ['unitRentCurrency']).toUpperCase();
    return ApartmentUnitDraft(
      unitId: _firstText(m, const ['unitId']),
      unitName: _firstText(m, const ['unitName']),
      unitRent: _firstText(m, const ['unitRent']),
      unitRentFrequency: freq.isNotEmpty ? freq : 'Per Day',
      unitFloor: PropertyUnitFloor.parse(m['unitFloor']),
      operationMode: resolveOperationMode(mode, freq),
      unitDescription: _firstText(m, const ['unitDescription']),
      unitRentCurrency: currency.isEmpty ? 'TZS' : currency,
    );
  }
}
