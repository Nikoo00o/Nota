import 'dart:async';
import 'dart:ui';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/locales.dart';
import 'package:app/core/enums/app_update.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

class AppSettingsRepositoryImpl extends AppSettingsRepository {
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  /// stream controller to add the updates
  final StreamController<AppUpdate> _updateController = StreamController<AppUpdate>();
  /// broadcast stream that is used to listen for updates for the app bloc
  late final Stream<AppUpdate> _updateStream;

  static const String CONFIG_DARK_THEME = "DARK_THEME";

  static const String CONFIG_AUTO_SAVE = "CONFIG_AUTO_SAVE";

  AppSettingsRepositoryImpl({required this.localDataSource, required this.appConfig}){
    _updateStream = _updateController.stream.asBroadcastStream();
  }

  @override
  Future<Locale> getCurrentLocale() async {
    final Locale? savedLocale = await localDataSource.getLocale();
    return savedLocale ?? (Locales.getSupportedSystemLocale() ?? appConfig.defaultLocale);
  }

  @override
  Future<Locale?> getStoredLocale() => localDataSource.getLocale();

  @override
  Future<void> setLocale(Locale? locale) async {
    await localDataSource.setLocale(locale);
    _updateController.add(AppUpdate.LOCALE); // update app bloc and force a rebuild
  }

  @override
  Future<bool> isDarkTheme() => localDataSource.getConfigValue(configKey: CONFIG_DARK_THEME);

  @override
  Future<void> setDarkTheme({required bool useDarkTheme}) async {
    await localDataSource.setConfigValue(configKey: CONFIG_DARK_THEME, configValue: useDarkTheme);
    _updateController.add(AppUpdate.DARK_THEME); // update app bloc and force a rebuild
  }


  @override
  Future<Duration> getLockscreenTimeout() async {
    final Duration? savedTimeout = await localDataSource.getLockscreenTimeout();
    return savedTimeout ?? appConfig.defaultLockscreenTimeout;
  }

  @override
  Future<void> setLockscreenTimeout({required Duration duration}) =>
      localDataSource.setLockscreenTimeout(duration: duration);

  @override
  Future<void> addLog(LogMessage log) => localDataSource.addLog(log);

  @override
  Future<List<LogMessage>> getLogs() => localDataSource.getLogs();

  @override
  Future<void> setLogLevel(LogLevel logLevel) => localDataSource.setLogLevel(logLevel: logLevel);

  @override
  Future<LogLevel> getLogLevel() async => (await localDataSource.getLogLevel()) ?? appConfig.defaultLogLevel;

  @override
  Future<void> setAutoSave({required bool autoSave}) =>
      localDataSource.setConfigValue(configKey: CONFIG_AUTO_SAVE, configValue: autoSave);

  @override
  Future<bool> getAutoSave() => localDataSource.getConfigValue(configKey: CONFIG_AUTO_SAVE);

  @override
  StreamSubscription<AppUpdate> listen(void Function(AppUpdate) callback) => _updateStream.listen(callback);
}
