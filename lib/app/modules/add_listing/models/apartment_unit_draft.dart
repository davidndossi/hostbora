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
    required this.unitDescription,
  });

  /// Persistent id (saved on the parent property). Empty for legacy rows until re-saved.
  final String unitId;
  final String unitName;
  final String unitRent;
  /// Same labels as listing [rentFrequency] (e.g. Per Day).
  final String unitRentFrequency;
  /// [PropertyUnitFloor] index (0 = ground).
  final int unitFloor;
  /// Optional; may be empty.
  final String unitDescription;

  /// Key for dropdowns when [unitId] is missing (legacy JSON).
  String get selectionKey =>
      unitId.trim().isNotEmpty ? unitId.trim() : '__n:${unitName.trim()}';

  Map<String, dynamic> toJson() => {
        'unitId': unitId.trim(),
        'unitName': unitName,
        'unitRent': unitRent,
        'unitRentFrequency': unitRentFrequency,
        'unitFloor': unitFloor,
        'unitDescription': unitDescription,
      };

  factory ApartmentUnitDraft.fromJson(Map<String, dynamic> m) {
    final freq = m['unitRentFrequency']?.toString().trim() ??
        m['rentFrequency']?.toString().trim() ??
        '';
    return ApartmentUnitDraft(
      unitId: m['unitId']?.toString() ?? '',
      unitName: m['unitName']?.toString() ?? '',
      unitRent: m['unitRent']?.toString() ?? '',
      unitRentFrequency: freq.isNotEmpty ? freq : 'Per Day',
      unitFloor: PropertyUnitFloor.parse(m['unitFloor']),
      unitDescription: m['unitDescription']?.toString() ?? '',
    );
  }
}
