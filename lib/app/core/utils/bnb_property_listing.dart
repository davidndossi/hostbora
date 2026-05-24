import '../../data/local/db/property_local_data_source.dart';

/// Resolves BnB listing ids (`propertyRef`, `local_<id>`, `legacy_<id>`).
PropertyRecord? findBnbPropertyForListing(
  String listingId,
  List<PropertyRecord> properties,
) {
  final id = listingId.trim();
  if (id.isEmpty) return null;
  for (final p in properties) {
    if (p.propertyRef.trim() == id) return p;
    if ('local_${p.id}' == id || 'legacy_${p.id}' == id) return p;
  }
  return null;
}

/// Canonical listing id used when saving bookings and merging pending rows.
String bnbHubRefForProperty(PropertyRecord record) {
  final ref = record.propertyRef.trim();
  return ref.isNotEmpty ? ref : 'legacy_${record.id}';
}
