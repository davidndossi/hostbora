/// One apartment unit row added from the “Add Unit” flow.
class ApartmentUnitDraft {
  const ApartmentUnitDraft({
    required this.unitName,
    required this.unitRent,
    required this.unitDescription,
  });

  final String unitName;
  final String unitRent;
  /// Optional; may be empty.
  final String unitDescription;

  Map<String, dynamic> toJson() => {
        'unitName': unitName,
        'unitRent': unitRent,
        'unitDescription': unitDescription,
      };

  factory ApartmentUnitDraft.fromJson(Map<String, dynamic> m) {
    return ApartmentUnitDraft(
      unitName: m['unitName']?.toString() ?? '',
      unitRent: m['unitRent']?.toString() ?? '',
      unitDescription: m['unitDescription']?.toString() ?? '',
    );
  }
}
