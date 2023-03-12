import 'package:app/core/constants/locales.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/config/shared_config.dart';

class AppConfig extends SharedConfig {
  /// Returns the relative path to the folder which contains the note files inside of the [getApplicationDocumentsDirectory]
  String get noteFolder => "notes";

  Locale get defaultLocale => Locales.en;

  String get appTitle => "Nota";

  /// If the app was in the background for this amount of time, then a new local login with the password will be needed if
  /// the accounts auto login setting is set to false!
  Duration get lockscreenTimeout => const Duration(seconds: 30);

  /// If the developer test pages should be shown inside of the menu drawer, or not.
  bool get showDeveloperOptions => true;
}
