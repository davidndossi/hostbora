/// Result of merging one server row into phone storage.
class RemoteRowMerge<T> {
  const RemoteRowMerge({required this.record, required this.keptLocal});

  final T record;

  /// True when the phone copy was newer and was left in place.
  final bool keptLocal;
}

/// Compares phone and server edit times so the newer copy wins.
class SyncFreshness {
  SyncFreshness._();

  /// Milliseconds from an epoch number or an ISO-8601 string. `0` when unknown.
  static int millis(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) {
      final n = raw.toInt();
      if (n <= 0) return 0;
      // Seconds since epoch are smaller than millisecond timestamps.
      return n < 100000000000 ? n * 1000 : n;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return 0;
    final asNum = num.tryParse(text);
    if (asNum != null) return millis(asNum);
    final parsed = DateTime.tryParse(text);
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  /// First populated edit time on a server payload.
  static int fromMap(Map<dynamic, dynamic> map) {
    for (final key in const [
      'updated_at_ms',
      'updatedAtMs',
      'updated_at',
      'updatedAt',
      'modified_at',
      'modifiedAt',
      'lastModified',
      'last_modified',
    ]) {
      final value = millis(map[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  /// True when the phone copy was edited more recently than the server copy.
  ///
  /// A missing server clock does not count as newer. The phone wins in that
  /// case only when it was edited after it was created.
  static bool phoneIsNewer({
    required int localUpdatedMs,
    required int localCreatedMs,
    required int remoteUpdatedMs,
  }) {
    final local = localUpdatedMs > 0 ? localUpdatedMs : localCreatedMs;
    if (local <= 0) return false;
    if (remoteUpdatedMs <= 0) {
      return localUpdatedMs > localCreatedMs && localCreatedMs > 0;
    }
    return local > remoteUpdatedMs;
  }
}
