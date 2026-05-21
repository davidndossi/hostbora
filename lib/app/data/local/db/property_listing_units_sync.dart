import '../../../core/values/property_unit_floor.dart';
import 'property_unit_local_data_source.dart';

/// Replaces `property_units` rows for [propertyRef] after saving the parent property.
Future<void> syncPropertyUnitsForListingSave({
  required PropertyUnitLocalDataSource unitLocal,
  required String propertyRef,
  required bool isApartment,
  required List<Map<String, dynamic>> apartmentUnitMaps,
  required String minRentalDuration,
  required String listingRentFrequency,
  required String listingRentRaw,
  required String singleUnitName,
  required int rooms,
  required int maxGuests,
}) async {
  final ref = propertyRef.trim();
  if (ref.isEmpty) return;

  await unitLocal.deleteByPropertyRef(ref);
  final now = DateTime.now().millisecondsSinceEpoch;

  if (isApartment && apartmentUnitMaps.isNotEmpty) {
    var i = 0;
    for (final m in apartmentUnitMaps) {
      final uid = (m['unitId'] ?? '').toString().trim();
      final unitId = uid.isNotEmpty ? uid : 'u_${now}_$i';
      i++;

      final unitName = (m['unitName'] ?? '').toString().trim();
      if (unitName.isEmpty) continue;

      final rentRaw = (m['unitRent'] ?? '').toString().replaceAll(',', '');
      final rent = double.tryParse(rentRaw) ?? 0;

      final freqRaw = (m['unitRentFrequency'] ?? '').toString().trim();
      final freq = freqRaw.isNotEmpty ? freqRaw : listingRentFrequency;

      final notes = (m['unitDescription'] ?? '').toString();
      final floor = PropertyUnitFloor.parse(m['unitFloor']);

      await unitLocal.insert(
        PropertyUnitRecord(
          id: 0,
          propertyUnitRef: unitId,
          propertyRef: ref,
          unitName: unitName,
          status: 'vacant',
          rentAmount: rent,
          rentFrequency: freq,
          minRentDuration: minRentalDuration,
          maxGuests: maxGuests,
          rooms: rooms,
          floor: floor,
          notes: notes,
          createdAtMs: now,
        ),
      );
    }
    return;
  }

  final rent = double.tryParse(listingRentRaw.replaceAll(',', '')) ?? 0;
  final name = singleUnitName.trim().isNotEmpty ? singleUnitName.trim() : 'Main unit';

  await unitLocal.insert(
    PropertyUnitRecord(
      id: 0,
      propertyUnitRef: 'main',
      propertyRef: ref,
      unitName: name,
      status: 'vacant',
      rentAmount: rent,
      rentFrequency: listingRentFrequency,
      minRentDuration: minRentalDuration,
      maxGuests: maxGuests,
      rooms: rooms,
      floor: 0,
      notes: '',
      createdAtMs: now,
    ),
  );
}
