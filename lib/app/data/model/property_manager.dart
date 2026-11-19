class DirectoryOption {
  DirectoryOption({required this.key, required this.label});

  factory DirectoryOption.fromJson(Map<String, dynamic> json) {
    return DirectoryOption(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  final String key;
  final String label;
}

class PropertyManager {
  PropertyManager({
    required this.id,
    required this.displayName,
    required this.location,
    required this.locationLabel,
    required this.propertyTypes,
    required this.propertyTypeLabels,
    required this.propertyCount,
    this.hostScore,
    this.bio,
    required this.certified,
    this.phone,
    this.email,
  });

  factory PropertyManager.fromJson(Map<String, dynamic> json) {
    return PropertyManager(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      locationLabel: json['locationLabel']?.toString() ?? '',
      propertyTypes: _strings(json['propertyTypes']),
      propertyTypeLabels: _strings(json['propertyTypeLabels']),
      propertyCount: _toInt(json['propertyCount']),
      hostScore: json['hostScore'] == null ? null : _toInt(json['hostScore']),
      bio: json['bio']?.toString(),
      certified: json['certified'] == true,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }

  final String id;
  final String displayName;
  final String location;
  final String locationLabel;
  final List<String> propertyTypes;
  final List<String> propertyTypeLabels;
  final int propertyCount;
  final int? hostScore;
  final String? bio;
  final bool certified;
  final String? phone;
  final String? email;
}

class PropertyManagerDirectory {
  PropertyManagerDirectory({
    required this.locations,
    required this.propertyTypes,
    required this.propertyBands,
    required this.managers,
  });

  factory PropertyManagerDirectory.fromJson(Map<String, dynamic> json) {
    return PropertyManagerDirectory(
      locations: _options(json['locations']),
      propertyTypes: _options(json['propertyTypes']),
      propertyBands: _options(json['propertyBands']),
      managers: json['managers'] is List
          ? (json['managers'] as List)
              .whereType<Map>()
              .map((item) => PropertyManager.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  final List<DirectoryOption> locations;
  final List<DirectoryOption> propertyTypes;
  final List<DirectoryOption> propertyBands;
  final List<PropertyManager> managers;
}

List<DirectoryOption> _options(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => DirectoryOption.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> _strings(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
