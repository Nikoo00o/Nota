import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_color.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:synchronized/synchronized.dart';

// ignore_for_file: avoid_print

/// Logger subclasses should override [logToConsole] with the preferred way to log into the console.
///
/// Before the static methods of the logger are used, the instance needs to be initialised with [initLogger]!
///
/// Subclasses can also override [logToStorage] if the logs should be stored, or [addColorForConsole] to add different
/// color strings to the log messages in the console.
class Logger {
  static const LogColor VERBOSE_COLOR = LogColor(128, 191, 255); // light blue
  static const LogColor DEBUG_COLOR = LogColor(166, 77, 255); // magenta
  static const LogColor INFO_COLOR = LogColor(128, 255, 128); // light green
  static const LogColor WARN_COLOR = LogColor(255, 255, 0); // yellow
  static const LogColor ERROR_COLOR = LogColor(255, 0, 0); // red
  static const LogColor _RESET_COLOR = LogColor(255, 255, 255); // white

  static const int consoleBufferSize = 1000;

  static Logger? _instance;

  static final Lock _lock = Lock();

  /// The current [LogLevel] of the logger. All logs with a higher value than this will be ignored and only the more
  /// important logs with a lower [LogLevel] will be printed and stored!
  /// Set it to [LogLevel.VERBOSE] to log everything!
  LogLevel logLevel;

  /// Initializes the current [logLevel] of the logger. All logs with a higher value than this will be ignored and only
  /// the more important logs with a lower [LogLevel] will be printed and stored!
  /// Set it to [LogLevel.VERBOSE] to log everything!
  Logger({required this.logLevel});

  /// Has to be called at the start of the main function to enable logging with a subclass of Logger
  static void initLogger(Logger instance) {
    if (_instance != null) {
      verbose("Overriding old logger instance $_instance with $instance");
    }
    _instance = instance;
  }

  static void error(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.ERROR, error, stackTrace);
  }

  static void warn(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.WARN, error, stackTrace);
  }

  static void info(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.INFO, error, stackTrace);
  }

  static void debug(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.DEBUG, error, stackTrace);
  }

  static void verbose(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.VERBOSE, error, stackTrace);
  }

  /// Returns if the current [logLevel] is set high enough, so that the [targetLevel] would be logged into the console and
  /// storage!
  ///
  /// This can be used for performance improvement to prevent execution of some logging code!
  static bool canLog(LogLevel targetLevel) => targetLevel.index <= _instance!.logLevel.index;

  /// returns the current log level of the logger
  static LogLevel get currentLogLevel => _instance!.logLevel;

  /// The main log method that is called by the static log methods. will log to console, storage, etc...
  Future<void> log(String? message, LogLevel level, Object? error, StackTrace? stackTrace) async {
    if (canLog(level) == false) {
      return;
    }
    final LogMessage logMessage =
        LogMessage(message: message, level: level, error: error, stackTrace: stackTrace, timestamp: DateTime.now());
    _wrapLog(convertLogMessageToConsole(logMessage)).forEach(logToConsole);
    addConsoleDelimiter();

    //var s = stdout.terminalColumns;

    await _lock.synchronized(() => logToStorage(logMessage)); // the static log methods will not await this, so it has to
    // be synchronized!
  }

  /// Adds a delimiter between the logs. can also be overridden in sub classes.
  void addConsoleDelimiter() {
    logToConsole(String.fromCharCodes(List<int>.generate(80, (int index) => "-".codeUnits.first)));
  }

  String convertLogMessageToConsole(LogMessage logMessage) {
    final StringBuffer output = StringBuffer();
    output.write(addColorForConsole(logMessage.level).toString());
    output.write(logMessage.toString());
    output.write(_RESET_COLOR.toString());
    return output.toString();
  }

  /// Wraps the log for the console
  List<String> _wrapLog(String log) =>
      RegExp(".{1,$consoleBufferSize}").allMatches(log).map((Match match) => match.group(0)!).toList();

  /// This can also be overridden in a subclass to provide different [LogColor]'s for the [LogLevel]
  LogColor addColorForConsole(LogLevel level) {
    LogColor? color;
    switch (level) {
      case LogLevel.ERROR:
        color = ERROR_COLOR;
        break;
      case LogLevel.WARN:
        color = WARN_COLOR;
        break;
      case LogLevel.INFO:
        color = INFO_COLOR;
        break;
      case LogLevel.DEBUG:
        color = DEBUG_COLOR;
        break;
      case LogLevel.VERBOSE:
        color = VERBOSE_COLOR;
        break;
    }
    return color;
  }

  @override
  String toString() {
    return '$runtimeType{logLevel: $logLevel}';
  }

  /// Can be overridden in the subclass to log the final log message string into the console in different ways.
  ///
  /// The default is just a call to [print]
  void logToConsole(String logMessage) {
    print(logMessage);
  }

  /// Can be overridden in the subclass to store the final log message in a file.
  ///
  /// Important: the call to this method will not be awaited, but it will be synchronized, so that only ever one log call
  /// is writing to it at the same time!
  ///
  /// The default is just a call to do nothing
  Future<void> logToStorage(LogMessage logMessage) async {}
}
