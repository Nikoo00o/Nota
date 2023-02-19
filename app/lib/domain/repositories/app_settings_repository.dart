import 'dart:ui';

/// Contains all global app config options that the user can change which are not specific to the account!
abstract class AppSettingsRepository {
  const AppSettingsRepository();

  /// Returns the stored, or default locale
  Future<Locale> getCurrentLocale();

  /// Stores the [locale]
  Future<void> setLocale(Locale locale);
}
