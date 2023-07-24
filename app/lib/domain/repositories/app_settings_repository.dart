import 'dart:async';
import 'dart:ui';

import 'package:app/core/enums/app_update.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

/// Contains all global app config options that the user can change which are not specific to the account (so they
/// are only locally stored and  not on the server)!
abstract class AppSettingsRepository {
  const AppSettingsRepository();

  /// Returns the stored locale, or the system settings locale, or the default locale if the previous one was null, or
  /// not supported!
  Future<Locale> getCurrentLocale();

  /// Returns the stored locale if one was stored and null otherwise
  Future<Locale?> getStoredLocale();

  /// Stores the [locale] and also updates the [AppBloc]
  Future<void> setLocale(Locale? locale);

  /// If the dark theme should be used (default false).
  Future<bool> isDarkTheme();

  /// Updates the dark theme and also updates the [AppBloc]
  Future<void> setDarkTheme({required bool useDarkTheme});

  /// the time the app needs to be in the background to require a local password login again.
  Future<Duration> getLockscreenTimeout();

  /// see [getLockscreenTimeout]
  Future<void> setLockscreenTimeout({required Duration duration});

  Future<void> addLog(LogMessage log);

  Future<List<LogMessage>> getLogs();

  /// overrides the one from the app config
  Future<void> setLogLevel(LogLevel logLevel);

  /// stored, or default from the app config
  Future<LogLevel> getLogLevel();

  /// when navigating back from note editing
  Future<void> setAutoSave({required bool autoSave});
  /// when navigating back from note editing. default is false
  Future<bool> getAutoSave();

  /// Called from the [AppBloc] to listen to updates
  StreamSubscription<AppUpdate> listen(void Function(AppUpdate) callback);
}
