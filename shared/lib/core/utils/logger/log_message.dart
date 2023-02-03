import 'package:shared/core/enums/log_level.dart';

class LogMessage {
  final String? message;
  final LogLevel level;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  const LogMessage({
    this.message,
    required this.level,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write("$timestamp $level ");
    bool alreadyHasText = false;
    if (message != null) {
      buffer.write(message);
      alreadyHasText = true;
    }
    if (error != null) {
      if (alreadyHasText) {
        buffer.write(", ");
      }
      buffer.write("Error: $error");
      alreadyHasText = true;
    }
    if (stackTrace != null) {
      if (alreadyHasText) {
        buffer.write(", ");
      }
      buffer.write("StackTrace: $stackTrace");
    }
    return buffer.toString();
  }
}
