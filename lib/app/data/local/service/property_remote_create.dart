import '../../model/general_response.dart';
import '../../repository/app_repository.dart';

/// One remote insert per property ref.
///
/// Saving a property and account sync can both POST `/api/properties` for the
/// same local row. A second POST inserts another row because the phone keeps
/// the `local_…` ref it already sent as `property_ref`.
class PropertyRemoteCreate {
  PropertyRemoteCreate._();

  static final Map<String, Future<bool>> _inFlight = {};
  static final Set<String> _accepted = {};

  static bool wasAccepted(String propertyRef) =>
      _accepted.contains(propertyRef.trim());

  static bool isInFlight(String propertyRef) =>
      _inFlight.containsKey(propertyRef.trim());

  static Future<bool>? wait(String propertyRef) => _inFlight[propertyRef.trim()];

  /// HTTP completed. A missing response code still counts: the call returned
  /// a body instead of throwing, and treating that as failure used to enqueue
  /// a second create.
  static bool responseAccepted(GeneralResponse res) {
    final code = (res.responseCode ?? '').trim();
    return code.isEmpty || code == '0' || code == '200' || code == '201';
  }

  /// Returns true when this ref is already on the server (this call or an
  /// earlier one in the same app session).
  static Future<bool> once({
    required AppRepository repository,
    required Map<String, dynamic> payload,
  }) async {
    final ref = (payload['property_ref'] ?? '').toString().trim();
    if (ref.isEmpty) return false;
    if (_accepted.contains(ref)) return true;
    final pending = _inFlight[ref];
    if (pending != null) return pending;

    final future = _post(repository, ref, payload);
    _inFlight[ref] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight[ref], future)) {
        _inFlight.remove(ref);
      }
    }
  }

  static Future<bool> _post(
    AppRepository repository,
    String ref,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await repository.createProperty(payload);
      final ok = responseAccepted(res);
      if (ok) _accepted.add(ref);
      return ok;
    } catch (_) {
      return false;
    }
  }
}
