/// Request payload for publishing a new listing (all steps data).
class AddListingRequest {
  AddListingRequest({
    this.propertyName,
    this.propertyType,
    this.streetAddress,
    this.latitude,
    this.longitude,
    this.baseNightlyRate,
    this.cleaningFee,
    this.instantBook = true,
    this.petsAllowed = false,
    this.numberOfBedrooms,
    this.numberOfBaths,
    this.maxGuests,
  });

  /// Step 1
  final String? propertyName;
  final String? propertyType;
  final String? streetAddress;
  final double? latitude;
  final double? longitude;

  /// Capacity (rooms, baths, guests)
  final int? numberOfBedrooms;
  final double? numberOfBaths;
  final int? maxGuests;

  /// Pricing & rules
  final double? baseNightlyRate;
  final double? cleaningFee;
  final bool instantBook;
  final bool petsAllowed;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'propertyName': propertyName,
      'propertyType': propertyType,
      'streetAddress': streetAddress,
      'latitude': latitude,
      'longitude': longitude,
      'baseNightlyRate': baseNightlyRate,
      'cleaningFee': cleaningFee,
      'instantBook': instantBook,
      'petsAllowed': petsAllowed,
      'numberOfBedrooms': numberOfBedrooms,
      'numberOfBaths': numberOfBaths,
      'maxGuests': maxGuests,
    };
  }

  static AddListingRequest fromJson(Map<String, dynamic> json) {
    return AddListingRequest(
      propertyName: json['propertyName'] as String?,
      propertyType: json['propertyType'] as String?,
      streetAddress: json['streetAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      baseNightlyRate: (json['baseNightlyRate'] as num?)?.toDouble(),
      cleaningFee: (json['cleaningFee'] as num?)?.toDouble(),
      instantBook: json['instantBook'] as bool? ?? true,
      petsAllowed: json['petsAllowed'] as bool? ?? false,
      numberOfBedrooms: json['numberOfBedrooms'] as int?,
      numberOfBaths: (json['numberOfBaths'] as num?)?.toDouble(),
      maxGuests: json['maxGuests'] as int?,
    );
  }
}
