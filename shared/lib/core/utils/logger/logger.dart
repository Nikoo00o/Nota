import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

class Logger {
  static void error(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialized");
    _instance?.log(message, LogLevel.ERROR, error, stackTrace);
  }

  static void info(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialized");
    _instance?.log(message, LogLevel.INFO, error, stackTrace);
  }

  static void debug(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialized");
    _instance?.log(message, LogLevel.DEBUG, error, stackTrace);
  }

  static Logger? _instance;

  /// Has to be called at the start of the main function to enable logging with a subclass of Logger
  static void initLogger(Logger instance) => _instance = instance;

  static const int consoleBufferSize = 1000;

  List<String> _wrapLog(String log) =>
      RegExp(".{1,$consoleBufferSize}").allMatches(log).map((Match match) => match.group(0)!).toList();

  /// The main log method that is called by the static log methods. will log to console, storage, etc...
  Future<void> log(String? message, LogLevel level, Object? error, StackTrace? stackTrace) async {
    final LogMessage logMessage =
        LogMessage(message: message, level: level, error: error, stackTrace: stackTrace, timestamp: DateTime.now());
    _wrapLog(logMessage.toString()).forEach(logToConsole);
    // todo: maybe also store logs in a file
  }

  /// Can be overridden in the subclass to log the final log message string into the console in different ways
  void logToConsole(String logMessage) {
    print(logMessage);
  }
}
