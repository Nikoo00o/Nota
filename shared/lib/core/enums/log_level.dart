/// type of the log entry
enum LogLevel {
  /// 0
  ERROR,

  /// 1
  INFO,

  /// 2
  DEBUG;

  @override
  String toString() {
    switch (this) {
      case ERROR:
        return "ERROR:";
      case INFO:
        return "INFO:";
      case DEBUG:
        return "DEBUG:";
    }
  }
}
