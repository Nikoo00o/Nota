import 'dart:ui';

/// A list of locales that are used inside of the ap
class Locales {
  static const Locale de = Locale("de");

  static const Locale en = Locale("en");

  /// Returns the list of supported locales
  static const List<Locale> supportedLocales = <Locale>[en, de];
}
