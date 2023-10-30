import 'dart:async';
import 'dart:ui';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/enums/app_update.dart';
import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

/// Contains all global app config options that the user can change which are not specific to the account, so the
/// settings are only locally stored and not on the server
///
/// Most of the settings will will also not be reset when the account is changed (look at [resetAccountBoundSettings])!
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

  /// when active, this syncs every [AppConfig.automaticServerSyncDelay] after navigating to the note selection
  Future<void> setAutoServerSync({required bool autoServerSync});

  /// when active, this syncs every [AppConfig.automaticServerSyncDelay] after navigating to the note selection
  Future<bool> getAutoServerSync();

  /// saves the favourite notes/folders of the user to the local storage (this will be reset when switching accounts!)
  Future<void> setFavourites(Favourites favourites);

  /// returns the favourite notes and folders of the current user (this will be reset when switching accounts!)
  Future<Favourites> getFavourites();

  /// This calls [setFavourites] and [BiometricsRepository.enableBiometrics] and is called by [LogoutOfAccount]
  ///
  /// So this clears the settings that are reset when the account changes
  Future<void> resetAccountBoundSettings();

  /// Called from the [AppBloc] to listen to updates
  StreamSubscription<AppUpdate> listen(void Function(AppUpdate) callback);
}
