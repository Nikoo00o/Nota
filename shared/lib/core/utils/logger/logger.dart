import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

class Logger {
  static const String _DEBUG_COLOUR = "\x1b[35m"; // magenta
  static const String _INFO_COLOUR = "\x1b[32m";// green
  static const String _ERROR_COLOUR = "\x1b[31m"; // red
  static const String _RESET_COLOUR = "\x1b[0m"; // white

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
    final String logString = logMessage.toString();
    _wrapLog("${_addColourForConsole(level)}$logString$_RESET_COLOUR").forEach(logToConsole);
    // todo: maybe also store logs in a file
  }

  String _addColourForConsole(LogLevel level) {
    String? colour;
    switch (level) {
      case LogLevel.ERROR:
        colour = _ERROR_COLOUR;
        break;
      case LogLevel.INFO:
        colour = _INFO_COLOUR;
        break;
      case LogLevel.DEBUG:
        colour = _DEBUG_COLOUR;
        break;
    }
    return colour;
  }

  /// Can be overridden in the subclass to log the final log message string into the console in different ways
  void logToConsole(String logMessage) {
    print(logMessage);
  }
}
