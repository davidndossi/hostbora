/// Helpers for booking list API responses (GET /api/bookings/list, etc.).
class BookingApiResponse {
  BookingApiResponse._();

  static bool isSuccess(String? responseCode) =>
      responseCode == '0' ||
      responseCode == '200' ||
      responseCode == '201';

  /// Parses booking rows from [GeneralResponse.data].
  static List<Map<String, dynamic>> parseBookingsList(dynamic data) {
    if (data is Map && data['bookings'] is List) {
      return (data['bookings'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
