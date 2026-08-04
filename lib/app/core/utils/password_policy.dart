/// Shared strong-password rules for registration and password changes.
///
/// Requirements: at least 8 characters, with uppercase, lowercase, a digit,
/// and a special character.
abstract final class PasswordPolicy {
  static const int minLength = 8;

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  /// Any non-alphanumeric character counts as special.
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');

  static bool hasMinLength(String password) => password.length >= minLength;

  static bool hasUppercase(String password) => _upper.hasMatch(password);

  static bool hasLowercase(String password) => _lower.hasMatch(password);

  static bool hasDigit(String password) => _digit.hasMatch(password);

  static bool hasSpecial(String password) => _special.hasMatch(password);

  static bool isStrong(String password) =>
      hasMinLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasDigit(password) &&
      hasSpecial(password);

  /// First failing rule, or `null` when the password meets the policy.
  /// [isSw] selects Swahili copy.
  static String? validate(String? value, {bool isSw = false}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return isSw ? 'Nenosiri linahitajika' : 'Password is required';
    }
    if (!hasMinLength(password)) {
      return isSw
          ? 'Nenosiri lazima liwe na angalau herufi $minLength'
          : 'Password must be at least $minLength characters';
    }
    if (!hasUppercase(password)) {
      return isSw
          ? 'Nenosiri lazima liwe na herufi kubwa (A–Z)'
          : 'Password must include an uppercase letter (A–Z)';
    }
    if (!hasLowercase(password)) {
      return isSw
          ? 'Nenosiri lazima liwe na herufi ndogo (a–z)'
          : 'Password must include a lowercase letter (a–z)';
    }
    if (!hasDigit(password)) {
      return isSw
          ? 'Nenosiri lazima liwe na namba (0–9)'
          : 'Password must include a number (0–9)';
    }
    if (!hasSpecial(password)) {
      return isSw
          ? 'Nenosiri lazima liwe na alama maalum (mf. ! @ # \$ %)'
          : 'Password must include a special character (e.g. ! @ # \$ %)';
    }
    return null;
  }

  /// Short helper line for form hints (EN/SW).
  static String requirementsHint({bool isSw = false}) => isSw
      ? 'Angalau herufi $minLength, herufi kubwa, herufi ndogo, namba, na alama maalum'
      : 'At least $minLength characters, with uppercase, lowercase, a number, and a special character';
}
