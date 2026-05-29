import '../../data/local/db/expense_local_data_source.dart';
import '../../data/local/db/income_local_data_source.dart';
import '../../data/local/db/property_local_data_source.dart';

/// Matches income/expense rows to a single listing (rent or BnB).
class PropertyListingFinanceScope {
  const PropertyListingFinanceScope({
    required this.scopeRefs,
    required this.propertyName,
    required this.propertyLocation,
  });

  final Set<String> scopeRefs;
  final String propertyName;
  final String propertyLocation;

  static Future<PropertyListingFinanceScope> resolve({
    required String propertyId,
    required String propertyName,
    required String propertyLocation,
    required PropertyLocalDataSource propertyLocal,
  }) async {
    final scopeRefs = <String>{};
    final id = propertyId.trim();
    if (id.isNotEmpty) scopeRefs.add(id);

    if (id.isNotEmpty) {
      final rows = await propertyLocal.getAllNewestFirst();
      for (final r in rows) {
        final localId = 'local_${r.id}';
        final legacyId = 'legacy_${r.id}';
        if (r.propertyRef.trim() == id ||
            localId == id ||
            legacyId == id) {
          if (r.propertyRef.trim().isNotEmpty) {
            scopeRefs.add(r.propertyRef.trim());
          }
          scopeRefs.add(localId);
          scopeRefs.add(legacyId);
          break;
        }
      }
    }

    return PropertyListingFinanceScope(
      scopeRefs: scopeRefs,
      propertyName: propertyName.trim(),
      propertyLocation: propertyLocation.trim(),
    );
  }

  bool matchesIncome(IncomeRecord row) => _matchesRow(
        propertyRef: row.propertyRef,
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      );

  bool matchesExpense(ExpenseRecord row) => _matchesRow(
        propertyRef: '',
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      );

  bool _matchesRow({
    required String propertyRef,
    required String apartment,
    required String apartmentUnit,
    required String notes,
  }) {
    final pr = propertyRef.trim();
    if (pr.isNotEmpty && scopeRefs.isNotEmpty && scopeRefs.contains(pr)) {
      return true;
    }
    final apt = apartment.trim().toLowerCase();
    final unit = apartmentUnit.trim().toLowerCase();
    final notesLc = notes.trim().toLowerCase();
    final name = propertyName.toLowerCase();
    final loc = propertyLocation.toLowerCase();
    if (name.isEmpty && loc.isEmpty) return false;
    if (name.isNotEmpty &&
        (apt.contains(name) || unit.contains(name) || notesLc.contains(name))) {
      return true;
    }
    if (loc.isNotEmpty &&
        (apt.contains(loc) || unit.contains(loc) || notesLc.contains(loc))) {
      return true;
    }
    return false;
  }
}
