import 'package:app/core/constants/locales.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/config/shared_config.dart';

class AppConfig extends SharedConfig {
  /// Returns the relative path to the folder which contains the note files inside of the [getApplicationDocumentsDirectory]
  String get noteFolder => "notes";

  Locale get defaultLocale => Locales.en;

  String get appTitle => "nota";

  /// The theme of the app including the colors, etc
  ThemeData get theme => ThemeData.dark(useMaterial3: true);

  /// If the app was in the background for this amount of time, then a new local login with the password will be needed if
  /// the accounts auto login setting is set to false!
  Duration get screenSaverTimeout => const Duration(seconds: 30);

}
