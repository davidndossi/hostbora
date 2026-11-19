/// Referral code carried in https://hostbora.co.tz/r/{code}.
class ReferralLinks {
  ReferralLinks._();

  static String? pendingCode;

  /// Reads `/r/{code}` from an app link. Returns the code when one was stored.
  static String? capture(Uri? uri) {
    if (uri == null) return pendingCode;
    final match = RegExp(r'^/r/([^/]+)/?$').firstMatch(uri.path);
    if (match == null) return pendingCode;
    final raw = Uri.decodeComponent(match.group(1)!).trim();
    if (raw.isEmpty || raw == '*') return pendingCode;
    pendingCode = raw;
    return raw;
  }
}

/// Website / store handoff that should open Sign in.
///
/// Matches `https://hostbora.co.tz/app/signin` and `hostbora://signin`.
class SignInLinks {
  SignInLinks._();

  static bool pending = false;

  static bool capture(Uri? uri) {
    if (uri == null) return pending;
    if (_isSignIn(uri)) pending = true;
    return pending;
  }

  static bool _isSignIn(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'hostbora') {
      return uri.host.toLowerCase() == 'signin' ||
          uri.path.toLowerCase().contains('signin');
    }
    return uri.path.toLowerCase().startsWith('/app/signin');
  }
}
