import 'package:app/core/config/app_config.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:shared/core/utils/logger/logger.dart';

class AppLogger extends Logger {
  final AppConfig appConfig;
  final AppSettingsRepository appSettingsRepository;

  static const int _DELETE_THRESH_HOLD = 50;

  AppLogger({required super.logLevel, required this.appConfig, required this.appSettingsRepository});

  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }

  @override
  Future<void> logToStorage(LogMessage logMessage) async {
    if (appConfig.logIntoStorage) {
      try {
        await appSettingsRepository.addLog(logMessage);
        final List<LogMessage> logMessages = await appSettingsRepository.getLogs();
        if (logMessages.length > appConfig.amountOfLogsToKeep + _DELETE_THRESH_HOLD) {
          for (int i = 0; i < _DELETE_THRESH_HOLD; ++i) {
            await logMessages.elementAt(i).delete(); // delete the oldest logs in steps for performance
          }
        }
      } catch (_, __) {
        //ignored
      }
    }
  }
}
