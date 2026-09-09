/// Naming rules for property / listing display names.
abstract class PropertyNameRules {
  PropertyNameRules._();

  static const int minLength = 2;
  static const int maxLength = 100;

  /// Letters, digits, spaces, and common naming punctuation.
  /// Disallows emoji, symbols like @ $ % * =, and control characters.
  static final RegExp allowedPattern = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿ0-9][A-Za-zÀ-ÖØ-öø-ÿ0-9\s'\-.,&()/#]{0,98}$",
  );

  /// Characters permitted while typing (same set as [allowedPattern]).
  static final RegExp allowedInputChars = RegExp(
    r"[A-Za-zÀ-ÖØ-öø-ÿ0-9\s'\-.,&()/#]",
  );

  static String? validate(String? value, {required bool isSw}) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return isSw ? 'Jina la mali linahitajika' : 'Property name is required';
    }
    if (name.length < minLength) {
      return isSw
          ? 'Jina la mali liwe na herufi angalau $minLength'
          : 'Property name must be at least $minLength characters';
    }
    if (name.length > maxLength) {
      return isSw
          ? 'Jina la mali lisiwe zaidi ya herufi $maxLength'
          : 'Property name must be at most $maxLength characters';
    }
    if (!allowedPattern.hasMatch(name)) {
      return isSw
          ? 'Jina la mali linaweza kuwa na herufi, namba, nafasi, '
              "na alama (-) (') (.) (,) (&) (() ()) (/) (#) pekee"
          : 'Property name may only use letters, numbers, spaces, '
              "and - ' . , & ( ) / #";
    }
    return null;
  }
}
