class InputValidator {
  /// The password should contain at least 4 characters and it should contain at least one lowercase letter, one uppercase
  /// letter and one number. returns true if the password is valid
  static bool validatePassword(String password) =>
      password.length >= 4 &&
      RegExp(r"[A-Z]").hasMatch(password) &&
      RegExp(r"[a-z]").hasMatch(password) &&
      RegExp(r"\d").hasMatch(password);
}
