import 'dart:ui';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/locales.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl extends AppSettingsRepository {
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  static const String CONFIG_DARK_THEME = "DARK_THEME";

  const AppSettingsRepositoryImpl({required this.localDataSource, required this.appConfig});

  @override
  Future<Locale> getCurrentLocale() async {
    final Locale? savedLocale = await localDataSource.getLocale();
    return savedLocale ?? (Locales.getSupportedSystemLocale() ?? appConfig.defaultLocale);
  }

  @override
  Future<Locale?> getStoredLocale() => localDataSource.getLocale();

  @override
  Future<void> setLocale(Locale? locale) => localDataSource.setLocale(locale);

  @override
  Future<bool> isDarkTheme() => localDataSource.getConfigValue(configKey: CONFIG_DARK_THEME);

  @override
  Future<void> setDarkTheme({required bool useDarkTheme}) =>
      localDataSource.setConfigValue(configKey: CONFIG_DARK_THEME, configValue: useDarkTheme);

  @override
  Future<Duration> getLockscreenTimeout() async {
    final Duration? savedTimeout = await localDataSource.getLockscreenTimeout();
    return savedTimeout ?? appConfig.defaultLockscreenTimeout;
  }

  @override
  Future<void> setLockscreenTimeout({required Duration duration}) =>
      localDataSource.setLockscreenTimeout(duration: duration);
}
