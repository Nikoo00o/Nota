import 'package:app/core/config/sensitive_data.dart';
import 'package:app/core/constants/locales.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/enums/log_level.dart';

class AppConfig extends SharedConfig {
  /// Returns the relative path to the folder which contains the note files inside of the [getApplicationDocumentsDirectory]
  String get noteFolder => "notes";

  /// The base folder within the [getApplicationDocumentsDirectory] where all other files and folders are stored!
  ///
  /// The hive database boxes will also be stored here
  String get baseFolder => "nota";

  Locale get defaultLocale => Locales.en;

  String get appTitle => "Nota";

  /// Used when creating the user key from the password (which will only be stored inside the app)
  String get userKeySalt => SensitiveData.userKeySalt;

  /// If the app was in the background for this amount of time, then a new local login with the password will be needed if
  /// the accounts auto login setting is set to false!
  Duration get defaultLockscreenTimeout => const Duration(seconds: 30);

  /// If the developer test pages should be shown inside of the menu drawer, or not.
  bool get showDeveloperOptions => true;

  LogLevel get defaultLogLevel => LogLevel.VERBOSE;

  int get amountOfLogsToKeep => 350;
}
