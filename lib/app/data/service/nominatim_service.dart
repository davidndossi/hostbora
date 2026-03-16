import 'package:dio/dio.dart';

/// One search result from OpenStreetMap Nominatim.
class NominatimPlace {
  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.placeId,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;
    return NominatimPlace(
      displayName: json['display_name'] as String? ?? '',
      lat: lat,
      lon: lon,
      placeId: json['place_id']?.toString(),
    );
  }

  final String displayName;
  final double lat;
  final double lon;
  final String? placeId;
}

/// Fetches address suggestions and coordinates from OpenStreetMap Nominatim.
/// Use a 1s delay between requests (Nominatim usage policy).
class NominatimService {
  NominatimService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {
      'User-Agent': 'PaaYangu/1.0 (property listing app)',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final Dio _dio;
  DateTime? _lastRequestTime;

  Future<List<NominatimPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    await _throttle();

    try {
      final response = await _dio.get<List>(
        '/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'addressdetails': 1,
          'limit': 6,
          'countrycodes': 'tz', // Restrict to Tanzania only
        },
      );

      final list = response.data;
      if (list == null || list.isEmpty) return [];

      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => NominatimPlace.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocode: get address string for a lat/lon (e.g. after user taps on map).
  Future<NominatimPlace?> reverseGeocode(double lat, double lon) async {
    await _throttle();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'addressdetails': 1,
        },
      );
      final data = response.data;
      if (data == null) return null;
      return NominatimPlace.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _throttle() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed.inMilliseconds < 1100) {
        await Future<void>.delayed(Duration(milliseconds: 1100 - elapsed.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();
  }
}
