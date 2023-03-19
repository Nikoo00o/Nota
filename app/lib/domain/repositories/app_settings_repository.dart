import 'dart:ui';

import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

/// Contains all global app config options that the user can change which are not specific to the account!
abstract class AppSettingsRepository {
  const AppSettingsRepository();

  /// Returns the stored locale, or the system settings locale, or the default locale if the previous one was null, or
  /// not supported!
  Future<Locale> getCurrentLocale();

  /// Returns the stored locale if one was stored and null otherwise
  Future<Locale?> getStoredLocale();

  /// Stores the [locale]
  Future<void> setLocale(Locale? locale);

  /// If the dark theme should be used (default false).
  Future<bool> isDarkTheme();

  Future<void> setDarkTheme({required bool useDarkTheme});

  /// the time the app needs to be in the background to require a local password login again.
  Future<Duration> getLockscreenTimeout();

  /// see [getLockscreenTimeout]
  Future<void> setLockscreenTimeout({required Duration duration});

  Future<void> addLog(LogMessage log);

  Future<List<LogMessage>> getLogs();

  Future<void> setLogLevel(LogLevel logLevel);

  Future<LogLevel> getLogLevel();

}
