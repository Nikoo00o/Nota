/// The type of the log entry (a lower level is more important)
enum LogLevel {
  /// 0
  ERROR,

  /// 1
  WARN,

  /// 2
  INFO,

  /// 3
  DEBUG,

  /// 4
  VERBOSE;

  @override
  String toString() {
    switch (this) {
      case ERROR:
        return "ERROR";
      case WARN:
        return "WARN";
      case INFO:
        return "INFO";
      case DEBUG:
        return "DEBUG";
      case VERBOSE:
        return "VERBOSE";
    }
  }
}
