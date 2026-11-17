/// Mirrors the backend's strong-password regex so the register/change-password
/// screens can show a live checklist instead of only failing after submit.
class PasswordRules {
  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasUpper(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool hasLower(String v) => v.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String v) => v.contains(RegExp(r'\d'));
  static bool hasSpecial(String v) => v.contains(RegExp(r'[^A-Za-z0-9]'));

  static bool isStrong(String v) => hasMinLength(v) && hasUpper(v) && hasLower(v) && hasDigit(v) && hasSpecial(v);
}
