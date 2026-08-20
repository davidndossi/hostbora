import '../../data/local/db/property_local_data_source.dart';
import 'property_listing_image_assigner.dart';

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

/// Match by display name when listing id is missing or stale.
PropertyRecord? findBnbPropertyForLabel(
  String propertyLabel,
  List<PropertyRecord> properties,
) {
  final wanted = propertyLabel.trim();
  if (wanted.isEmpty) return null;
  for (final p in properties) {
    final label = p.propertyName.trim().isNotEmpty
        ? p.propertyName.trim()
        : p.propertyLocation.trim();
    if (label == wanted) return p;
  }
  return null;
}

/// Canonical listing id used when saving bookings and merging pending rows.
String bnbHubRefForProperty(PropertyRecord record) {
  final ref = record.propertyRef.trim();
  return ref.isNotEmpty ? ref : 'legacy_${record.id}';
}

/// Cover path for a booking card: keep network API images, else property cover / LR asset.
String resolveBnbBookingPropertyImage({
  required String? listingId,
  required String propertyLabel,
  required List<PropertyRecord> properties,
  String existingImageUrl = '',
}) {
  final existing = existingImageUrl.trim();
  if (existing.isNotEmpty &&
      PropertyListingImageAssigner.isNetworkPath(existing)) {
    return existing;
  }
  final property = findBnbPropertyForListing(listingId ?? '', properties) ??
      findBnbPropertyForLabel(propertyLabel, properties);
  if (property == null) return existing;
  return PropertyListingImageAssigner.resolveDisplayPath(
    storedPath: property.coverPhotoPath,
    propertyRef: bnbHubRefForProperty(property),
    localPropertyId: property.id,
    propertyName: property.propertyName,
  );
}
