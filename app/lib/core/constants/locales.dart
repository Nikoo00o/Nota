import 'dart:ui';

/// A list of locales that are used inside of the ap
class Locales {
  static const Locale de = Locale("de");

  static const Locale en = Locale("en");

  /// Returns the list of supported locales
  static const List<Locale> supportedLocales = <Locale>[en, de];

  /// This is the same order as the supported locales themselves, but has an additional translation key at the end for the
  /// system language!
  static const List<String> localeTranslationKeys = <String>["locale.en", "locale.de", "locale.system"];
}
